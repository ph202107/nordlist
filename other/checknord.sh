#!/bin/bash
#
# Check that the NordVPN account is logged in, the VPN is connected,
# and that meshnet is enabled. Check continuously at timed intervals
# and run a command at each interval.
#
# This script was written in response to issues I was having with a
# remote PC, while meshnet was the only connection method to that PC.
#
# Add your VPN connection command in 'function check_connect'.
# Add a command to run every interval in 'function interval_command'.
#
# To create a login token, visit https://my.nordaccount.com/
# Services - NordVPN - Manual Setup - Generate New Token
logintoken=""
#
# Time in seconds to wait between checks:
refresh_interval="3600"
#
# How many attempts to login, connect, or enable meshnet before quitting
max_attempts="10"
#
#
function countdown_timer {
    # $1 = time in seconds
    echo
    echo "Countdown $1s. Cycle $icount"
    date
    echo -e "Type 'R' to resume"
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
function check_login {
    #
    if nordvpn account | grep -i "not logged in"; then
        lcount=$(( lcount + 1 ))
        if (( lcount <= max_attempts )); then
            echo
            echo "Login Attempt #$lcount"
            date
            nordvpn login --token "$logintoken"
            countdown_timer "60"
            check_nord
        else
            echo
            echo "Too many login attempts ($lcount).  Quitting"
            date
            echo
            exit
        fi
    fi
}
function check_connect {
    #
    connectstatus=$(nordvpn status | grep -i "Status" | cut -f2 -d':' | cut -c 2- | tr '[:upper:]' '[:lower:]')
    #
    if [[ "$connectstatus" != "connected" ]]; then
        ccount=$(( ccount + 1 ))
        if (( ccount <= max_attempts )); then
            echo
            echo "Connect Attempt #$ccount"
            date
            #
            nordvpn connect --group P2P United_States
            #
            countdown_timer "60"
            check_nord
        else
            echo
            echo "Too many connect attempts ($ccount).  Quitting"
            date
            echo
            exit
        fi
    fi
}
function check_meshnet {
    #
    meshnet=$( nordvpn settings | grep -i "Meshnet" | cut -f2 -d' ' | tr -d '\n' )
    #
    if [[ "$meshnet" != "enabled" ]]; then
        ecount=$(( ecount + 1 ))
        if (( ecount <= max_attempts )); then
            echo
            echo "Enable Meshnet Attempt #$ecount"
            date
            nordvpn set meshnet enabled
            countdown_timer "60"
            check_nord
        else
            echo
            echo "Too many enable attempts ($ecount).  Quitting"
            date
            echo
            exit
        fi
    fi
}
function interval_command {
    # This command runs once per cycle
    #
    nordvpn meshnet peer refresh
    #
}
function check_nord {
    # comment-out unneded functinos
    #
    check_login
    check_connect
    check_meshnet
    interval_command
    #
    icount=$(( icount + 1 ))
    countdown_timer "$refresh_interval"
    check_nord
}
#
lcount="0"      # login count
ccount="0"      # connect count
ecount="0"      # enable meshnet count
icount="0"      # interval cycle count
#
echo -e '\033]2;'Nord_Monitor'\007'  # window title
clear -x
echo
echo "/// NordVPN Monitor ///"
echo
if [[ -z $logintoken ]]; then
    echo "No login token provided."
    echo
    read -n 1 -r -p "Continue? (y/n) "; echo
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exit"
        echo
        exit
    fi
fi
#
check_nord
