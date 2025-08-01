#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
clear_color='\033[0m'
query_base=$(echo 'title = "GPON Home Gateway" && port = 443 && "jQuery 1.12"')
API_KEY="$(cat $HOME/.zoomeye_api_key)"
if [ ! -f $HOME/.zoomeye_api_key ]; then
    echo "You need to register a free account with Zoomeye to use this script."
    echo "(Protip: use a temporary email address, not your normal one. They don't seem to mind.)"
    echo "Search for temp email in your browser of choice, then go to"
    echo "https://www.zoomeye.ai/cas/en-US/ui/register"
    echo "to create an account. Once you've logged in, go to"
    echo "https://www.zoomeye.ai/profile/info"
    echo "to copy your API key. Create a text file named .zoomeye_api_key"
    echo "in your home directory and you're ready to go."
    echo '(ex: echo "fCc692-618abDd-This-Is-Not-A-Real-Key-722b" > ~/.zoomeye_api_key)'
    echo "Alternatively, you can alter this script and set your key as the permanent value of the second variable on line 3."
    exit 1
fi
if [ ! command -v base64 ]; then
    echo "base64 utility not found!"
    exit 1
fi
shift $((OPTIND-1))
while getopts ":hpm" opt; do
   case $opt in
   h)
     echo "This script can be run with no arguments to run a default search,"
     echo "with -p (plus) to add additional search terms,"
     echo "with -n (not) to exclude results matching a pattern,"
     printf "using the syntax"
     printf" ./zoomeye.sh -[pn]"
     printf "${red} parameter ${green} value"
     printf "${clear_color}\n"
     printf "ex: ./zoomeye-nokia.sh -n ${red}country ${green}Brazil${clear_color}\n"
     exit 0
     ;;
   p)
     variable="$1"
     value="$2"
     modifier="$(printf '&&' && printf "$variable = " && printf "$value")"
     
       ;;
   m)
     modifier='-'
     ;;
  \?)
     echo "Executed with no -m or -p flag: assuming -p"
     modifier='%2B'
     ;;
   esac
done
shift $((OPTIND-1))
if [ ! -d "$HOME/.tmp" ]; then
    mkdir $HOME/.tmp
fi
echo "Checking if Zoomeye is up..."
curl -m 15 -s https://www.zoomeye.ai > /dev/null
zoomeye_status=$?
if [ $zoomeye_status != 0 ]; then
    echo "It appears that Zoomeye's servers are down..."
    echo "Pinging IP address 154.93.109.29..."
    ping -w 10 154.93.109.29 > /dev/null 2>/dev/null
    ping_status="$?"
    if [ "$ping_status" != 0 ]; then
        echo "Got no response."
        exit $ping_status
    else
        echo "Ping worked - check your DNS settings"
        exit $zoomeye_status
    fi
fi
echo 'Searching Zoomeye for:'
printf "${red}"
echo "Title: GPON Home Gateway"
printf "${yellow}"
echo "Port: 443"
printf "${green}"
echo "jQuery 1.12"
printf "${clear_color}"
if  [ ! -z $first_arg ]; then
    printf "${yellow}"
    printf "$(urlencode -d $first_arg)"
    printf "${clear_color}"
    echo ""
fi
if  [ ! -z $second_arg ]; then
    printf "${red}"
    printf "$(urlencode -d $second_arg)"
    printf "${clear_color}"
    echo ""
fi
curl_request () {
curl -s -X GET "https://api.zoomeye.ai/host/search?query=$get_request" -H "API-KEY:$API_KEY" | grep -oE "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | sort -u | tee $HOME/.tmp/iplist
}
echo "IPs matching query terms:"
printf "${red}"
if  [ ! -z $first_arg ]; then
    if  [ ! -z $second_arg ]; then
        get_request="${query_base}${modifier}${first_arg}${modifier}${second_arg}"
        curl_request
    else
       get_request="${query_base}${modifier}${first_arg}"
       curl_request
    fi
else
    get_request="${query_base}"
    curl_request
fi
printf "${clear_color}"
if ! command -v ipinfo 2>&1 >/dev/null; then
        if ! command -v geoiplookup 2>&1 >/dev/null; then
           echo "No geoip tool found, exiting..."
           exit 1
        else
           geoip="geoiplookup"
        fi
else
        geoip="ipinfo"
fi
if [[ ! -z $(cat $HOME/.tmp/iplist) ]]; then
    echo "Finding geolocations..."
    printf "${green}"
    if [ "$geoip" == "ipinfo" ]; then
       cat $HOME/.tmp/iplist | tr '\n' ' ' > $HOME/.tmp/iplist-space
       ips_to_search="$(cat $HOME/.tmp/iplist-space)"
       for i in $ips_to_search; do
          ipinfo $i | grep -v "Core" | grep -v "Anycast" | head -n 5
          printf "\n"
       done
       rm $HOME/.tmp/iplist-space
    else
       cat $HOME/.tmp/iplist | xargs -n 1 $geoip
    fi
rm $HOME/.tmp/iplist
printf "${clear_color}"
fi
