#!/bin/bash
#
# Check that NordVPN is logged in and that meshnet is enabled.
# Continuously refresh the peer list on a timer.
#
# Security Alert: login info is in plain text
#
# To create a login token, visit https://my.nordaccount.com/
# Services - NordVPN - Access Token - Generate New Token
logintoken=""
#
# Time in seconds to wait before refreshing the peer list again:
refresh_interval="3600"
#
#
function countdown_timer {
    # $1 = time in seconds
    #
    echo
    echo "Countdown $1s. Peer Refresh $rcount"
    echo -e "Type 'R' to resume"
    date
    echo "Countdown:"
    for ((i="$1"; i>=0; i--))
    do
        days=$(( "$i" / 86400 ))
        if (( days >= 1 )); then
            echo -ne "    $days days and $(date -u -d "@$i" +%H:%M:%S)\033[0K\r"
        else
            echo -ne "    $(date -u -d "@$i" +%H:%M:%S)\033[0K\r"
        fi
        read -t 1 -n 1 -r -s countinput
        if [[ "$countinput" =~ ^[Rr]$ ]]; then
            echo -e "    Stopped\033[0K\r"
            break
        fi
    done
    echo
}
function check_meshnet {
    #
    if nordvpn account | grep -i "not logged in"; then
        lcount=$(( lcount + 1 ))
        if (( lcount <= 10 )); then
            echo
            echo "Login Attempt #$lcount"
            date
            nordvpn login --token "$logintoken"
            countdown_timer "60"
            check_meshnet
        else
            echo
            echo "Too many login attempts ($lcount).  Quitting"
            date
            echo
            exit
        fi
    fi
    #
    meshnet=$( nordvpn settings | grep -i "Meshnet" | cut -f2 -d' ' | tr -d '\n' )
    #
    if [[ "$meshnet" == "disabled" ]]; then
        ecount=$(( ecount + 1 ))
        if (( ecount <= 10 )); then
            echo
            echo "Enable Meshnet Attempt #$ecount"
            date
            nordvpn set meshnet enabled
            countdown_timer "60"
            check_meshnet
        else
            echo
            echo "Too many enable attempts ($ecount).  Quitting"
            date
            echo
            exit
        fi
    fi
    #
    nordvpn meshnet peer refresh
    #
    rcount=$(( rcount + 1 ))
    countdown_timer "$refresh_interval"
    check_meshnet
}
#
lcount="0"      # login count
ecount="0"      # enable meshnet count
rcount="0"      # refresh peer list count
#
echo -e '\033]2;'Meshnet_Monitor'\007'  # window title
clear -x
echo
echo "/// Meshnet Monitor ///"
echo
check_meshnet
