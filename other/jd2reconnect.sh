#!/bin/bash
#
# This script works with the NordVPN Linux CLI and the JDownloader2
# "reconnect" option.  It can also run standalone or with other apps.
#
# The script creates a list of the top 20 Recommended Servers based on
# your current VPN location. When the script is called it checks if your
# current server is in the list, deletes that entry, and connects to
# the next server. When no servers remain it connects to another city
# and retrieves a new list.
#
# Requires 'curl' and 'jq'
#   "sudo apt install curl jq"
# Make sure the script is executable
#   "chmod +x jd2reconnect.sh"
#
# Login and connect to VPN before use.
#
# In JDownloader2:
#   Settings - Reconnect
#       Reconnect Method: External Tool
#       Command to use = full path to this script
#   Advanced Settings:
#       To prevent excessive notifications and a reconnect timeout.
#       Refer to the "minuptime" variable below.  Default=10
#       "Reconnect: Seconds To Wait For IP Change"
#           Default=300.  Enter a value greater than (minuptime * 60) eg "700"
#       "Reconnect: Seconds to Wait for Offline"
#            Default=60.  Enter a value greater than (minuptime * 60) eg "700"
#   Usage: (JD2 toolbar button)
#       "Perform a Reconnect"
#
# The script avoids rapid VPN server changes by forcing a minimum VPN
# uptime. If the script runs before this time is reached, it will pause
# until the minimum uptime has passed. Then it will reconnect to VPN.
# Monitor the log for updates during the wait.
# The script's process ID (PID) will be shown in the log and in the
# notification. If you need to stop the process for whatever reason,
# open a terminal and run 'kill <PID>', then restart JD2.
#
# To begin with a fresh server list simply delete the existing one.
# A new list will be created based on your current VPN location.
#
# The script will populate the list with recommended servers from the
# NordVPN API. You could also create a custom server list instead.
# Use the full server hostnames, one server per line, last line is: EOF
# Note that servers are deleted from this list as the script is used.
#
# Known Issues:
#  -Connection may fail if you have another device already connected
#   to the target server using the same technology and protocol.
#   Can delete the in-use server from the list or use another city.
#  -The API will sometimes return recommended servers that are not from
#   the connected city.
#  -The script does not check for VPN account login status and has no
#   automatic handling of VPN connection errors.
#
# =====================================================================
#
# This variable can be used to set the paths below, or set each path
# individually. This is the directory from which the script is run:
jd2base="$(dirname "${BASH_SOURCE[0]}")"
#
# Specify the full path and filename for the server list.
# eg. jd2list="/home/$USER/Downloads/nord_jd2servers.txt"
jd2list="$jd2base/nord_jd2servers.txt"
#
# Specify the full path and filename for the log file.
logfile="$jd2base/nord_jd2log.txt"
#
# Automatically open a terminal window and follow the log. "y" or "n"
# Tested with gnome-terminal, see "function logstart" for more options.
logmonitor="y"
#
# Show desktop notifications for reconnects and errors. "y" or "n"
notifications="y"
#
# Specify the minimum VPN uptime required before changing servers.
# Prevents rapid server changes.  Value is in minutes.
minuptime="10"
#
# If the connection to a server fails, remove that server from the server list. "y" or "n"
removefailed="y"
#
# Reload the Nordlist Cinnamon applet when the script exits.
# This will change the icon color (for connection status) immediately.
# Only for the Cinnamon DE with the applet installed. "y" or "n"
nordlistapplet="n"
#
# Reload the "Network Manager" Cinnamon applet when the script exits.
# This removes duplicate "nordlynx" entries from the applet. "y" or "n"
nmapplet="n"
#
# Specify alternate cities to use as the server lists are emptied.
# These will be used in rotation.
cities=( "New_York" "Los_Angeles" "Chicago" "Dallas" ) # "London" "Amsterdam" "Frankfurt" )
#
# =====================================================================
#
function checkdepends {
    for cmd in curl jq nordvpn; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Exit." >&2
            exit 1
        fi
    done
}
function log {
    message="$1"        # the message to log
    level="${2:-INFO}"  # log levels: INFO|RECONNECT|ERROR|WARNING|NOTIFY default:INFO
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    #
    # Log to terminal (debug) and logfile
    echo "$timestamp [$level] $message"
    [[ -n "$logfile" ]] && echo "$timestamp [$level] $message" >> "$logfile"
    #
    # Send a desktop notification for specific levels
    if [[ "$notifications" =~ ^[Yy]$ && "$level" =~ ^(RECONNECT|ERROR|WARNING|NOTIFY)$ ]]; then
        notify-send "JD2 - $level" "$message"
    fi
}
function logstart {
    # check if the log file exists
    if [[ ! -e "$logfile" ]]; then
        # create the log file
        if ! touch "$logfile"; then
            echo "Error: Failed to create log file at $logfile. Exit." >&2
            exit 1
        fi
        log "Created: $logfile"
        log "Logging: $0"
    fi
    # separator
    log "===================================================="
    #
    # open a terminal to follow the log
    if [[ "$logmonitor" =~ ^[Yy]$ ]]; then
        # check if 'tail' process is already running for this logfile
        if ! pgrep -f "tail -n50 -f $logfile$" > /dev/null; then
            # launch the log monitor in a new terminal window
            gnome-terminal --title="JD2_LOGS" -- bash -c "tail -n50 -f $logfile; exec bash"
            #
            # other terminals not tested:
            # xterm -T "JD2_LOGS" -hold -e "tail -n50 -f $logfile" &
            # xfce4-terminal --title="JD2_LOGS" --command="tail -n50 -f $logfile" &
            # konsole --title="JD2_LOGS" -e "tail -n50 -f $logfile" &
            #
            log "Opened the log monitor. CTRL-C to quit."
            log "Log: $logfile"
        fi
    fi
}
function checkserverlist {
    # check if the server list exists
    if [[ ! -e "$jd2list" ]]; then
        log "No server list found."
        # create the server list
        if ! touch "$jd2list"; then
            log "Failed to create a server list at $jd2list. Exit." "ERROR"
            exit 1
        fi
        updateserverlist
    fi
}
function updateserverlist {
    log "Retrieving a server list from NordVPN API..."
    #
    if ! curl "https://api.nordvpn.com/v1/servers/recommendations?limit=20" | jq -r '.[].hostname' > "$jd2list"; then
        log "Failed to retrieve a server list from API. Exit." "ERROR"
        exit 1
    fi
    # check if the server list is empty
    if [[ ! -s "$jd2list" ]]; then
        log "Server list is empty after retrieval. Exit." "ERROR"
        exit 1
    fi
    echo "EOF" >> "$jd2list"
    log "Server list retrieved successfully."
    log "List: $jd2list"
}
function getcurrentinfo {
    # current VPN status information
    if ! readarray -t nordvpnstatus < <(nordvpn status) || [[ "${#nordvpnstatus[@]}" -eq 0 ]]; then
        log "Command 'nordvpn status' failure. Exit." "ERROR"
        reload_applet
        exit 1
    fi
    #
    for line in "${nordvpnstatus[@]}"
    do
        lc_line="${line,,}"     # lowercase
        case "$lc_line" in
            *"status"*)
                connectedstatus="${lc_line##*: }"
                ;;
            *"hostname"*)
                currenthost="${lc_line##*: }"
                shorthost="${currenthost%%.*}"
                ;;
            *"city"*)
                rawcity="${line##*: }"
                # replace all spaces with underscores
                currentcity="${rawcity// /_}"
                ;;
            *"uptime"*)
                norduptime="$line"
                ;;
        esac
    done
    # default to N/A
    currenthost=${currenthost:-N/A}
    shorthost=${shorthost:-N/A}
    currentcity=${currentcity:-N/A}
    #
    servercount=$(( $(wc -l < "$jd2list") - 1 ))
    #
    # calculate uptime in total minutes
    weeks=$(echo "$norduptime" | grep -oP '\d+(?= week)' | head -1)
    days=$(echo "$norduptime" | grep -oP '\d+(?= day)' | head -1)
    hours=$(echo "$norduptime" | grep -oP '\d+(?= hour)' | head -1)
    minutes=$(echo "$norduptime" | grep -oP '\d+(?= minute)' | head -1)
    # default to 0
    weeks=${weeks:-0}
    days=${days:-0}
    hours=${hours:-0}
    minutes=${minutes:-0}
    # current uptime in minutes.  Avoids issue with eg. "Uptime: 2 Hours 1 Minute"
    currentuptime=$(( (weeks * 7 * 24 * 60) + (days * 24 * 60) + (hours * 60) + minutes ))
    waittime=$(( minuptime - currentuptime ))
}
function checkuptime {
    if [[ "$connectedstatus" != "connected" ]]; then
        log "VPN is not connected."
        return
    fi
    # check the current VPN uptime and pause if necessary
    if (( currentuptime < minuptime )); then
        log "VPN Uptime: ${currentuptime}m  Min: ${minuptime}m  Wait: ${waittime}m  PID: $$" "WARNING"
        log "Pausing for $waittime minutes before reconnecting."
        log "Run 'kill $$' to stop the script."
    fi
    # loop until the minimum uptime is reached
    while (( currentuptime < minuptime )); do
        sleep 60
        getcurrentinfo
        log "VPN Uptime: ${currentuptime}m  Min: ${minuptime}m  Wait: ${waittime}m"
        if (( currentuptime >= minuptime )); then
            log "Good to go."
            break
        fi
    done
    log "VPN $norduptime"
}
function changeserver {
    if [[ "$connectedstatus" == "connected" ]]; then
        log "Current Server: $currentcity $shorthost"
        # remove the current server from the list
        if grep -q "$currenthost" "$jd2list"; then
            grep -v "$currenthost" "$jd2list" > "${jd2list}.tmp" && mv "${jd2list}.tmp" "$jd2list"
            log "Removed $shorthost from the server list."
        else
            log "$shorthost is not in the server list."
        fi
    fi
    # get the next server from the top of the list
    nextserverhost=$( head -n 1 "$jd2list" )
    # remove everything after the first '.'
    nextserver="${nextserverhost%%.*}"
    #
    if [[ "$nextserver" == "EOF" ]]; then
        # no more servers, rotate to next city
        getnextcity
        log "Server list is empty. Connecting to $nextcity." "NOTIFY"
        if nordvpn connect "$nextcity"; then
            log "Connection successful."
            reload_applet
        else
            log "Connection to $nextcity failed. Exit." "ERROR"
            reload_applet
            exit 1
        fi
        sleep 3
        updateserverlist
        return
    fi
    # connect to the next server
    log "Connect to the next server: $nextserver"
    if nordvpn connect "$nextserver"; then
        log "Connection successful."
        reload_applet
    else
        log "Connection to $nextserver failed. Exit." "ERROR"
        if [[ "$removefailed" =~ ^[Yy]$ ]]; then
            grep -v "$nextserverhost" "$jd2list" > "${jd2list}.tmp" && mv "${jd2list}.tmp" "$jd2list"
            log "Removed $nextserverhost from the server list."
        fi
        reload_applet
        exit 1
    fi
    # wait for other system notifications
    #sleep 3
}
function getnextcity {
    index="0"   # first city is default.  array index starts at zero
    for i in "${!cities[@]}"; do
        if [[ "${cities[$i]}" == "$currentcity" ]]; then
            index=$(( (i + 1) % ${#cities[@]} ))    # wrap around to start
            break
        fi
    done
    nextcity="${cities[index]}"
}
function reload_applet {
    # reload Cinnamon Desktop applets
    if [[ "$nordlistapplet" =~ ^[Yy]$ ]] && [[ -d "/home/$USER/.local/share/cinnamon/applets/nordlist_tray@ph202107" ]]; then
        # reload 'nordlist_tray@ph202107' - changes the icon color (for connection status) immediately.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'nordlist_tray@ph202107' string:'APPLET'
    fi
    if [[ "$nmapplet" =~ ^[Yy]$ ]]; then
        # reload 'network@cinnamon.org' - removes extra 'nordlynx' entries.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'network@cinnamon.org' string:'APPLET'
    fi
}
#
# =====================================================================
#
checkdepends
logstart
checkserverlist
#
getcurrentinfo
checkuptime
changeserver
getcurrentinfo
getnextcity
#
log "VPN: $currentcity $shorthost  List: $servercount  Next: $nextcity" "RECONNECT"
#
# eg. "VPN: New_York us8369  List: 13  Next: Los_Angeles"
# "VPN: New_York us8369" == The current VPN connection, city and server number.
# "List: 13" == The number of servers that are in the server list.
# "Next: Los_Angeles" == When the server list is empty, connect to this city next.
#
