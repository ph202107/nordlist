#!/bin/bash
#
# Check that the NordVPN account is logged in, the VPN is connected,
# and that meshnet is enabled. Check continuously at timed intervals
# and run commands at each interval.
#
# This script was written in response to issues I was having with a
# remote PC, while meshnet was the only connection method to that PC.
#
# Add the VPN connection command in 'function check_connect'
# Add commands to run at every interval in 'function interval_commands'
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
function check_login {
    #
    if [[ -z $logintoken ]]; then
        echo "No login token. Exit."
        echo
        exit
    fi
    if nordvpn account | grep -i "not logged in"; then
        logincount=$(( logincount + 1 ))
        if (( logincount <= max_attempts )); then
            echo
            echo "Login Attempt #$logincount"
            date
            nordvpn login --token "$logintoken"
            countdown_timer "60"
            check_nord
        else
            echo
            echo "Too many login attempts ($logincount).  Quitting"
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
        connectcount=$(( connectcount + 1 ))
        if (( connectcount <= max_attempts )); then
            echo
            echo "Connect Attempt #$connectcount"
            date
            # =========================================================
            nordvpn connect --group P2P United_States
            # =========================================================
            countdown_timer "60"
            check_nord
        else
            echo
            echo "Too many connect attempts ($connectcount).  Quitting"
            date
            echo
            exit
        fi
    fi
}
function check_meshnet {
    #
    meshnetstatus=$( nordvpn settings | grep -i "Meshnet" | cut -f2 -d' ' | tr -d '\n' )
    #
    if [[ "$meshnetstatus" != "enabled" ]]; then
        enablecount=$(( enablecount + 1 ))
        if (( enablecount <= max_attempts )); then
            echo
            echo "Enable Meshnet Attempt #$enablecount"
            date
            nordvpn set meshnet enabled
            countdown_timer "60"
            check_nord
        else
            echo
            echo "Too many enable attempts ($enablecount).  Quitting"
            date
            echo
            exit
        fi
    fi
}
function interval_commands {
    # these commands run once per cycle after other checks have passed
    # =================================================================
    nordvpn meshnet peer refresh
    # =================================================================
}
function countdown_timer {
    # $1 = time in seconds
    echo
    echo "Countdown $1s. Cycle $intervalcount"
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
function check_nord {
    # comment-out functions that are not needed
    #
    check_login
    check_connect
    check_meshnet
    interval_commands
    #
    intervalcount=$(( intervalcount + 1 ))
    countdown_timer "$refresh_interval"
    check_nord
}
#
logincount="0"      # login attempts
connectcount="0"    # connect attempts
enablecount="0"     # enable meshnet attempts
intervalcount="0"   # interval cycle count
#
echo -e '\033]2;'Nord_Monitor'\007'  # window title
clear -x
echo
echo "/// NordVPN Monitor ///"
echo
check_nord
