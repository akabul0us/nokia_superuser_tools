#!/usr/bin/env bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
clear_color='\033[0m'
if [ -z "$1" ]; then
    echo "IP address to check: "
    read ip
else
    ip="$1"
fi
trap keyint SIGINT
keyint() {
   printf "${red}Script killed by keyboard interrupt${clear_color}\n"
   exit 130
}
printf "${green}Checking ${red}$ip ${green}for connectivity...${clear_color}\n"
check_connect() {
ping -w 2 $ip > /dev/null
exit="$?"
}
check_connect
while [ "$exit" == 1 ]; do
   check_connect
done
if [ "$exit" == 0 ]; then
    printf "${green}The device at ${red}$ip ${green}is back online! ${clear_color}\n"
    exit 0
fi
