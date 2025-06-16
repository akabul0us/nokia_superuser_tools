#Nokia Superuser Tools
###Scripts, binaries and guide for finding, rooting, and bypassing 
security protocols to maintain persistent access to Nokia ONT devices.  

vulnerable models \(known\):  G-0425G-A, G-0425G-C, G-120W-F, 
G-140W-C, G-140W-G, G-140W-H,  G-1425G-A, G-1425G-B, G-240G-E, 
G-240W-C, G-240W-F, G-240W-G,  G-240W-J, G-241W-A, G-2425G-A, 
G-2425G-B, G-2426G-A.

##OVERVIEW

This repo has been divided into three sections:

-*Targeting*: finding vulnerable devices exposed to WAN
-*Exploitation*: unpacking, rewriting, and repacking the 
    configuration files from target devices to allow 
    root access over SSH
-*Post-exploitation*: changing internal settings on target
    devices to maintain remote root access 

Everything in the first two sections runs on your device,
everything in the third section \(except for the top-level script\)
runs on the target device. 

Any distribution of GNU/Linux or another Unix-like OS should 
work fine, as long as the requirements have been previously 
built and are located somewhere along the user's $PATH.

The compiled binaries in *Post-exploitation* - dropbearmulti, 
busybox, dirtyc0w, and some experimental binaries from 
[Medusa Embedded Toolkit](https://github.com/CyberDanube/medusa-embedded-toolkit\), have been statically compiled 
to be run on four target architectures. Two of these are MIPS: 
big and little endian. The other two are ARMv7, hard-float and 
"soft float" \(called endian-little or armel\).
The script used to modify the configuration, `nokia-use-ip-cfg` 
\(itself a modified version of [this script](https://gist.githubusercontent.com/rajkosto/e2b2455d457cc2be82dbb5c85e22d708/raw/f851ccbfe0c2466e21e48e5fafe639c0dd0f2eba/nokia-router-cfg-tool.py\)\) will also tell you
the endianness of the device it came from. If it says it's 
big endian, it can only be MIPS, as both ARM architectures 
are little endian. However, if it detects little endian, once 
you have logged in via SSH, you will have to check `/proc/cpuinfo` 
to determine the processor and board type.

Tbe code for dirtyc0w has been included and comes from [here.](https://raw.githubusercontent.com/dirtycow/dirtycow.github.io/refs/heads/master/dirtyc0w.c\)
The code for Busybox and dropbear would have made this repo enormous,
but you can find Busybox [here](https://github.com/mirror/busybox\) and Dropbear [here](https://github.com/mkj/dropbear\).

##HOW IT WORKS 

The usual method for configuring these devices is through an HTTP 
interface, served locally over port 80, but frequently exposed to the
WAN as well, over either port 443 \(https\) or port 8080. Typically,
the ISPs that install these allow their end users access with the
limited account "userAdmin" using the same password as the default 
PSK for their wifi. End users are not informed, however,  of the 
hard-coded login credentials for the superuser account, but these 
are easily found through a Google search and rarely have been changed.
Login as _AdminGPON_ with password _ALC#FGU_.

There are exceptions, but these exceptions typically do little for 
the overall security of these devices. For instance, Telmex ONTs 
have only one account, "TELMEX", with the privileges of the AdminGPON 
account. This account also uses the wifi password as the default 
login password, making these devices less easily accessed if discovered
exposed to the WAN. However, they come with WPS enabled by default, 
and their WPS instance is vulnerable to PixieDust, making accessing
the network and finding the superuser password trivial for an 
attacker with proximity to the device.

The configuration files for these devices can be saved on the page 
"Backup and Restore," creating a file named "config.cfg". This file 
can be easily decrypted to a readable .xml file, which contains 
many configuration options not available on any page of the 
standard HTTP interface. The most important of these are 
the ones that allow access via SSH, and bypass the "vtysh" shell,
allowing direct access to /bin/sh. Reupload of the configuration 
file causes the ONT to reboot, taking it offline for a few minutes. 
Once back online, SSH will be served either on port 22 or \(more commonly\) 
on port 8022. Credentials to login are ONTUSER:admin. 

For the zoomeye script, you must also register a free account on zoomeye. 
We are not promoting their service nor do we have any relationship with zoomeye, 
paid or otherwise. We encourage you to use any similar service you like 
to search for vulnerable devices using the same or similar parameters.   

For devices located in Spanish-speaking countries,  "GPON Home Gateway" 
may be substituted with "Terminal Óptica".  Port 443 is the most common 
for serving the login page over WAN, however some examples have been found
at port 8080 as well.  
jQuery 1.12 is the version most commonly associated with firmware that 
allows access with default credentials AdminGPON:ALC#FGU, however this 
may not work with every device you find that uses this version of jQuery.
By the same token, some devices running newer versions may still contain these 
hardcoded credentials. 
For whatever reason, zoomeye, shodan, and other IOT device search engines
may find one vulnerable device but fail to find more in the same IP subnet. 
The idea behind ip-range-scan.sh is to check these subnets to see if any 
other Nokia routers have their login pages exposed. Typically, if the 
hardcoded credentials work on one of them, they will work on all \(or almost all\) 
of the devices installed by the same ISP.  

##EXPLOITATION

Once authentication on a vulnerable device is achieved and the config.cfg 
file has been saved to the standard download directory, autopwn.sh can be 
used to unpack, modify, and repack this file in a matter of seconds, 
saving it as "dropbear" in the same directory that config.cfg was downloaded to. 
Uploading this file to the device will allow you root access via SSH.

decrypt-all.sh should probably be called something else as the  "encryption"
used for sensitive values in many of the .xml files is really more of an 
encoding than true encryption. More to the point, this script allows you 
to quickly strip out all of the values that Nokia deemed sensitive and 
view them in plain text.  In some implementations of the vulnerable 
firmware, no encryption or encoding is used for such values. However, 
those familiar with UNIX-based systems will recognize the occasional 
use of values that have been *actually* encrypted with one-way hashing
algorithms \(identifiable by their format beginning with a number between 
1 and 5 followed by $ and a string of 32 or 64 characters\). 
If you wish to decrypt such values, we recommend using hashcat. 

Although nokia-xml-editor sets the standard SSH port of 22 for incoming connections, 
iptables rules present on the vast majority of vulnerable devices will only 
allow connections to SSH over WAN using port 8022. For LAN-accessible devices, 
port 22 should work with no issues.  After uploading the altered config file 
to the target, it will reboot, and it will take a few minutes \(longer for PPPOE devices\) 
for it to come back online. Once the device is back online, access with the
nokia-connect script, using the IP address and port as arguments 1 and 2.


##POST-EXPLOITATION 

The two most common architectures for these SoCs are MIPS little endian
(mipsle-linux-uclibc\) and ARM endian little \(arm-linux-gnueabi\), 
typically MIPS 1004k and ARMv7l \(Cortex9, no hard float\).

Consequently, mipsle and armel have taken priority for static cross-compilation.
There are binaries included for MIPS big endian and ARM hard float devices, but
fewer of them \(no static busybox/dropbearmulti, for example\). 
dirtyc0w, fortunately, is available for all architectures.

Even the unrestricted shell has some restrictions -- at first. 
These devices run a variety of Linux kernels - 3.4, 3.18.21, 4.1.45 have all 
been observed - but what all of them have in common is vulnerability 
to a race condition in copy-on-write, exploited as "dirtyc0w". 
This allows changes to read-only files stored on the root squashfs 
filesystem  \(although these changes will not persist after a reboot\).
  
Most of the post_exploitation scripts do not require any binaries 
except those found by default on the devices, and should work 
regardless of the CPU type present. Endianness is determined 
and displayed during the unpacking of the config.cfg file. 
armv7l is always little endian, so any result showing big endian 
can be safely assumed to indicate MIPS. Once in the root shell, 
examine /proc/cpuinfo to find which architecture/SoC the device contains.

The devices built around mipsle still use uclibc-0.9.33.2 \(from 2012\). 
That's a huge pain to build a toolchain for in modern times,
so in order to produce working and updated binaries, they have 
been statically linked. \(Even maintainers of these devices using
the official propietary toolchains struggle to get them to work: 
see https://github.com/lxc/lxc/issues/3440\).  

There are several ways to get these files onto the target device,
as their stock firmware contains curl, wget, nc, and plenty of 
other fun tools \(including tcpdump\). \(They are badly deprecated 
versions, so make sure to check syntax\).  To persist after reboots, 
the target for these binaries is /configs/bin, /configs being the 
mount point for one of the UBI filesystems.  As space is limited, 
it is advisable to use /var as a staging area. Devices with a UBI
block available at /flash can also use this and simply symlink 
/configs/bin to /flash/bin.

In some cases, files larger than ~400K fail to upload over WAN. 
You can split and then concatenate the files, compress with bzip2/gzip,
or both. \(Make sure to get iptables to accept connections on the target 
device before beginning this process\).  Only do this if necessary - 
some devices will accept everything in both scripts and the appropriate 
bins directory as one big tarball.


##SCRIPTS 
 
`fix-mount`
Find which mount points have nodev, noexec, and/or nosuid tags and remove them 
`fix-ssh`
runs the new dropbear server on port 2244
`update-profile`
Runs in the background rewriting /etc/profile and /etc/home/ONTUSER/.bashprofile  with desirable parameters   \(to execute as a background process, append & \)
`update-iptables`
changes iptables policies to be as permissive as possible without breaking connectivity 
`new-seconf`
uses dirtyc0w exploit to rewrite read-only file /usr/etc/se.conf with security disabled
`new-guardian`
uses dirtyc0w exploit to rewrite read-only file /usr/exe/data_guardian.sh and allow modifications 
`chungus-web`
mounts a tmpfs on top of /webs, copies the gpon home chungus webpage to it, and runs busybox httpd instead of thttpd pointing to it

##DISCLAIMER

The fact of the matter is that all of the security issues on these devices can 
be fixed without replacing any hardware. There are MIPS routers with the exact 
CPU types found in these devices running the latest kernels. 

These security flaws are there because Nokia doesn't care enough to fix them, 
and ISPs care even less. It is only a matter of time before these glaring 
vulnerabilities are leveraged to run a massive botnet, spam email drive, 
DDoS attack, or some other similar nastiness. But perhaps action will be 
taken before such incidents if hundreds of thousands of routers suddenly 
display a big chungus \(that goes back to normal upon reboot without lasting 
damage\). One can only imagine, as this is purely hypothetical and the author 
of this repo would like to repeat once more that they do not condone any 
illegal activities.
