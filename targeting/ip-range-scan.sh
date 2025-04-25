#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
clear='\033[0m'
which nmap > /dev/null
exit=$?
if [ $exit -eq 1 ]; then
   echo "Either nmap is not installed, or it does not appear in your PATH."
   echo "Install nmap and try again."
   echo "https://www.github.com/nmap/nmap"
   exit 1
fi
if [ -z "$1" ]; then
    echo "IP range to scan (in CIDR notation): "
    read ipr
else
    ipr="$1"
fi
if [ -z "$2" ]; then
    echo "Port to scan: "
    read PORT
else
    PORT="$2"
fi
tempdir=$HOME/.tmp
mkdir $tempdir 2>/dev/null
touch $tempdir/scan00
echo "IPs from range $ipr open on port $PORT:" > $tempdir/scan00
echo "Scanning $ipr on port $PORT"
if [ "$EUID" -ne 0 ]
   then
   echo "Non-root user detected - limited to normal connect scan"
   nmap $ipr -p $PORT -vv | grep -i "discovered open" | cut -c 33- | sort -u > $tempdir/scan01
else
   echo "Root user detected - performing SYN stealth scan"
   nmap -sS $ipr -p $PORT -vv | grep -i "discovered open" | cut -c 33- | sort -u > $tempdir/scan01
fi
cat $tempdir/scan01 >> $tempdir/scan00
cat $tempdir/scan00
echo "Checking these IPs for the following parameters:"
printf "${yellow}"
echo "Title: GPON Home Gateway"
printf "${clear}"
curl_check () {
ips_2c="$(cat $tempdir/scan01 | sed 's/\n/\ /g')"
for I in $ips_2c; do
    printf "$I "
    curl -m 15 -s --insecure https://$I | grep -m1 -oE "GPON Home Gateway" > /dev/null
    exit_status=$?
    if [ $exit_status -eq 1 ]; then
       printf "${red}Non-Nokia\n${clear}"
    else
       printf "${green}Nokia detected\n${clear}"
    fi
done
}
curl_check | tee $tempdir/scan02
cat $tempdir/scan02 | grep "Nokia detected" | rev | cut -c 15- | rev > $tempdir/scan03
echo "Final list:"
printf "${green}"
cat $tempdir/scan03
rm $tempdir/scan00 $tempdir/scan01 $tempdir/scan02 $tempdir/scan03
printf "${clear}"
exit 0
