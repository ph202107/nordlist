#!/bin/bash
#
# This script works with the NordVPN Linux CLI and the JDownloader2
# "reconnect" option.  It might also work with other applications.
#
# Tested on Linux Mint 20.3
# Requires 'curl' and 'jq'.  eg "sudo apt install curl jq"
# Make sure the script is executable, eg "chmod +x jd.reconnect.sh"
#
# The script creates a list of the top 20 Recommended Servers based on
# your current location.  When the script is called it checks if your
# current server is in the list, deletes that entry, and connects to
# the next server. When no servers remain it connects to another city
# and retrieves a new list.
#
# In JDownloader2:
#   Settings - Reconnect
#       Reconnect Method: External Tool
#       Command to use = full path to this script
#   Usage: (JD2 toolbar button)
#       "Perform a Reconnect"
#
# To start off with a fresh list or a new location simply delete the
# existing server list.  A new list will be created.
#
# Specify the full path and filename to use for the server list.
# (Use the absolute path)
jdlist="/home/$USER/Downloads/jd.nordservers.txt"
#
# The initial list will be created based on your current location.
# Specify alternate cities to use when the server list is emptied.
# These will be used in rotation as subsequent server lists are emptied.
jdcity1="Vancouver"
jdcity2="Seattle"
jdcity3="Los_Angeles"
jdcity4="Toronto"
jdcity5="Atlanta"
#
# Send notifications when changing servers. "y" or "n"
notifications="y"
#
# =====================================================================
#
function getserverlist {
    curl --silent "https://api.nordvpn.com/v1/servers/recommendations" | jq --raw-output 'limit(20;.[]) | "\(.hostname)"' > "$jdlist"
    echo "EOF" >> "$jdlist"
}
function currentinfo {
    currenthost=$( nordvpn status | grep -i "Current server" | cut -f3 -d' ' )
    currentcity=$( nordvpn status | grep -i "City" | cut -f2 -d':' | cut -c 2- | tr ' ' '_' )
}
# create the list if it doesn't exist
if [[ ! -e "$jdlist" ]]; then
    getserverlist
fi
#
currentinfo
#
# check if the current hostname is in the list
if grep "$currenthost" "$jdlist"; then
    # remove the current hostname and save the list
    # grep inverse
    grep -v "$currenthost" "$jdlist" > tmpfile && mv tmpfile "$jdlist"
fi
#
# get the next server from the top of the list
nextserver=$( cat "$jdlist" | head -n 1 | cut -f1 -d'.' )
#
if [[ "$nextserver" == "EOF" ]]; then
    # if there are no more servers then change city and get a new list
    if [[ "$currentcity" == "$jdcity1" ]]; then
        nordvpn connect "$jdcity2"; wait
    elif [[ "$currentcity" == "$jdcity2" ]]; then
        nordvpn connect "$jdcity3"; wait
    elif [[ "$currentcity" == "$jdcity3" ]]; then
        nordvpn connect "$jdcity4"; wait
    elif [[ "$currentcity" == "$jdcity4" ]]; then
        nordvpn connect "$jdcity5"; wait
    else
        nordvpn connect "$jdcity1"; wait
    fi
    sleep 3
    getserverlist
else
    # connect to the next server
    nordvpn connect "$nextserver"; wait
fi
#
if [[ "$notifications" =~ ^[Yy]$ ]]; then
    currentinfo
    shorthost=$( echo "$currenthost" | cut -f1 -d'.' )
    servercount=$(( $(wc -l < "$jdlist") - 1 ))
    notify-send "JD Reconnect - $currentcity $shorthost" "$servercount servers remaining"
fi
