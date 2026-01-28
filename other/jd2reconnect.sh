#!/bin/bash
#
# This script works with the NordVPN Linux CLI and the JDownloader2
# "reconnect" option.  It can also run standalone or with other apps.
#
# The script generates a list of recommended VPN servers based on your
# current VPN location. Each time the script is called it connects to the
# next server in the list and removes it from the list. When no servers
# remain it connects to another city and retrieves a new list.
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
#  -Most cities worldwide have fewer than 60 servers in total, virtual
#   cities may have only 2. For server counts refer to nordlist.sh in:
#   Tools - NordVPN API - All VPN Servers - Server Count
#  -The script does not check for VPN account login status and has no
#   automatic handling of VPN connection errors.
#
# =====================================================================
#
# Set the minimum VPN uptime required before changing servers.
# Prevents rapid server changes.  Value is in minutes.
minuptime="10"
#
# Set the maximum number of servers to be added to the server list.
maxservers="60"
#
# Specify alternate cities to use as the server lists are emptied.
# These will be used in rotation. Use underscores if needed, no spaces.
# cities=( "London" "Frankfurt" "Amsterdam" "Paris" "Stockholm" )
cities=( "New_York" "Los_Angeles" "Chicago" "Miami" "Seattle" )
#
# Automatically open a terminal window and follow the log. "y" or "n"
# Tested with gnome-terminal, see "function logstart" for more options.
logmonitor="y"
#
# Show desktop notifications for reconnects and errors. "y" or "n"
notifications="y"
#
# Play a sound when the script exits.
# Options: "y"= play all, "n"= play none, "s"= only success, "e"= only errors
alertplay="n"       # y/n/s/e
alertvolume="50"    # Range 0 to 100
alertsuccess="/usr/share/sounds/freedesktop/stereo/complete.oga"
alerterror="/usr/share/sounds/freedesktop/stereo/phone-outgoing-busy.oga"
#
# Silence the alerts and the notifications during certain hours.
quietmode="n"       # "y" or "n"
quietstart="22"     # 24-hour format
quietend="08"       # 24-hour format
#
# If the connection to a server fails, remove that server from the
# server list. "y" or "n"
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
# Keep the log file trimmed to this many lines (with 2x buffer).
logtrim="1000"
# Color the log-levels when running directly in terminal. "y" or "n"
logcolor="y"
#
# =====================================================================
#
function checkdepends {
    for cmd in curl jq awk nordvpn; do
        if ! command -v "$cmd" &> /dev/null; then
            exitscript "1" "Error: $cmd is not installed. Exit."
        fi
    done
    # Ensures the script can talk to your audio and desktop session when called.
    # Applies to the alerts, notifications, applets, log monitor.
    # NOTE: If running as 'root' (via crontab/systemd), set your desktop user
    # ID manually, eg. user_id="1000"
    user_id="$(id -u)"
    export XDG_RUNTIME_DIR="/run/user/$user_id"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_id/bus"
}
function log {
    message="$1"
    level="${2:-INFO}"  # INFO|RECONNECT|ERROR|WARNING|NOTIFY|START
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    #
    # ANSI Color Codes (light)
    local reset="\033[0m"
    local boldred="\033[1;31m"
    local darkgrey="\033[90m"
    local lgreen="\033[0;92m"
    local lyellow="\033[0;93m"
    local lpurple="\033[0;95m"
    local lcyan="\033[0;96m"
    #
    local color=""
    case "$level" in
        ERROR)     color="$boldred" ;;
        WARNING)   color="$lyellow" ;;
        RECONNECT) color="$lgreen"  ;;
        NOTIFY)    color="$lcyan"   ;;
        *)         color="$lpurple" ;;
    esac
    #
    if [[ "${logcolor,,}" == "y" ]]; then
        if [[ "$level" == "START" ]]; then  # also color the $message
            echo -e "${darkgrey}${timestamp}${reset} ${color}[${level}] ${message}${reset}"
        else
            echo -e "${darkgrey}${timestamp}${reset} ${color}[${level}]${reset} ${message}"
        fi
    else
        echo "${timestamp} [${level}] ${message}"
    fi
    # clean text to log file
    if [[ -n "$logfile" ]]; then
        echo "$timestamp [$level] $message" >> "$logfile"
    fi
    # send desktop notification
    if [[ "${notifications,,}" == "y" && "$level" =~ ^(RECONNECT|ERROR|WARNING|NOTIFY)$ ]]; then
        if ! quiettime; then
            notify-send "JD2 - $level" "$message"
        fi
    fi
}
function logstart {
    if [[ ! -e "$logfile" ]]; then
        if ! touch "$logfile"; then
            exitscript "1" "Error: Failed to create log file at $logfile. Exit."
        fi
        log "Created: $logfile"
        log "Logging: $0"
    fi
    # separator
    log "====================================================" "START"
    #
    # trim logs when the buffer hits 2x $logtrim
    if (( $(wc -l < "$logfile") > ("${logtrim:-1000}" * 2) )); then
        tail -n "${logtrim:-1000}" "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
        log "Maintenance: Trimmed log back to $logtrim lines." "NOTIFY"
    fi
    # open a terminal to follow the log
    if [[ "${logmonitor,,}" == "y" ]]; then
        # check if 'tail' process is already running for this logfile
        if ! pgrep -f "tail -n50 -F $logfile$" > /dev/null; then
            # launch the log monitor in a new terminal window
            gnome-terminal --title="JD2_LOGS" -- bash -c "tail -n50 -F $logfile; exec bash"
            #
            # other terminals not tested:
            # xterm -T "JD2_LOGS" -hold -e "tail -n50 -F $logfile" &
            # xfce4-terminal --title="JD2_LOGS" --command="tail -n50 -F $logfile" &
            # konsole --title="JD2_LOGS" -e "tail -n50 -F $logfile" &
            #
            log "Opened the log monitor. CTRL-C to quit."
            log "Log: $logfile"
        fi
    fi
}
function checkserverlist {
    if [[ ! -e "$jd2list" ]]; then
        log "No server list found."
        if ! touch "$jd2list"; then
            exitscript "1" "Failed to create a server list at $jd2list. Exit."
        fi
        updateserverlist
    fi
}
function updateserverlist {
    log "Retrieving a server list from NordVPN API..."
    getcurrentinfo
    #
    if [[ "$connectedstatus" == "connected" ]]; then
        # find the api country code to use as an api filter
        apicountrycode=$(curl -s "https://api.nordvpn.com/v1/servers/countries" | \
        jq -r --arg country "$apicountry" '.[] | select(.name | ascii_downcase == $country) | .id')
        #
        if [[ -z "$apicountrycode" ]]; then
            exitscript "1" "Could not find API Country ID for $currentcountry. Exit."
        fi
        # there does not seem to be a 'city' filter for the api
        # retrieve all the servers for the country, jq filter by city, sort by load, save hostnames
        # ~3200 USA servers == ~8MB download.  Reducing 'limit=0' fails on USA queries.
        if ! curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=$apicountrycode&limit=0" | \
        jq -r --arg city "$apicity" '.[] | select(.locations[0].country.city.name | ascii_downcase == $city) | "\(.load) \(.hostname)"' | \
        sort -n | head -n "${maxservers:-60}" | awk '{print $2}' | shuf > "$jd2list"; then
            #
            exitscript "1" "Failed to pull servers for $currentcity. Exit."
        fi
    else
        # VPN disconnected
        if [[ $(nordvpn settings | grep -i "Kill Switch" | awk '{print $NF}') == "enabled" ]]; then
            log "VPN is disconnected with Kill Switch enabled." "WARNING"
        fi
        if ! curl -s "https://api.nordvpn.com/v1/servers/recommendations?limit=${maxservers:-60}" | jq -r '.[].hostname' | shuf > "$jd2list"; then
            exitscript "1" "Failed to retrieve a server list from API. Exit."
        fi
    fi
    # check if the server list is empty
    if [[ ! -s "$jd2list" ]]; then
        exitscript "1" "Server list is empty after retrieval. Exit."
    fi
    #
    logcity="$currentcity"
    if [[ "$currentcity" == "N/A" || -z "$currentcity" ]]; then
        logcity="Recommended"
    fi
    logcount=$(wc -l < "$jd2list")
    #
    echo "EOF" >> "$jd2list"
    log "$logcity server list retrieved with $logcount servers."
    log "List: $jd2list"
}
function getcurrentinfo {
    # current VPN status information
    if ! readarray -t nordvpnstatus < <(nordvpn status) || [[ "${#nordvpnstatus[@]}" -eq 0 ]]; then
        exitscript "2" "Command 'nordvpn status' failure. Exit."
    fi
    # default to N/A
    connectedstatus="N/A"   norduptime="N/A"    transferstats="N/A"
    currentcountry="N/A"    apicountry="N/A"    currenthost="N/A"
    currentcity="N/A"       apicity="N/A"       shorthost="N/A"
    #
    for line in "${nordvpnstatus[@]}"
    do
        value="${line##*: }"        # using <colon><space> as delimiter
        us_value="${value// /_}"    # replace spaces with underscores
        lc_value="${value,,}"       # lowercase value
        lc_line="${line,,}"         # lowercase line used for matching
        #
        case "$lc_line" in
            *"status"*)     connectedstatus="$lc_value";;
            *"hostname"*)   currenthost="$lc_value"
                            shorthost="${lc_value%%.*}";;
            *"country"*)    currentcountry="$us_value"
                            apicountry="$lc_value";;
            *"city"*)       currentcity="$us_value"
                            apicity="$lc_value";;
            *"transfer"*)   transferstats="$line";;
            *"uptime"*)     norduptime="$line"
                            read -ra uptime_array <<< "$norduptime";;
        esac
    done
    #
    servercount=$(( $(wc -l < "$jd2list") - 1 ))
    #
    # calculate uptime in minutes
    currentuptime="0"
    val="0"
    for word in "${uptime_array[@]}"    # eg. Uptime: 1 day 2 hours 1 minute 36 seconds
    do
        # word=${word//[,.]/}   # strip punctuation
        if [[ $word =~ ^[0-9]+$ ]]; then
            val=$((10#$word))   # force base-10 to also handle leading zeros
        else
            case "${word,,}" in
                week*)   (( currentuptime += val * 7 * 24 * 60 ));;
                day*)    (( currentuptime += val * 24 * 60 ));;
                hour*)   (( currentuptime += val * 60 ));;
                minute*) (( currentuptime += val ));;
            esac
        fi
    done
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
        sleep 60 & sleep_pid="$!"   # run timer in background so that ctrl-c or kill will be immediate
        wait "$sleep_pid" || break  # wait for sleep background process.  "wait" is interruptible
        getcurrentinfo
        # comment-out the next line to supress the heartbeat (logging every minute before reconnect)
        log "VPN Uptime: ${currentuptime}m  Min: ${minuptime}m  Wait: ${waittime}m"
        if (( currentuptime >= minuptime )); then
            log "Good to go."
            break
        fi
    done
    log "VPN $norduptime"
    log "$transferstats"
}
function deleteserver {
    # remove the current server from the list
    # called before and after a connection
    getcurrentinfo
    if [[ "$connectedstatus" != "connected" ]]; then
        return
    fi
    log "Current Server: $currentcity $currentcountry $shorthost"
    #
    if grep -qi "$currenthost" "$jd2list"; then
        grep -vi "$currenthost" "$jd2list" > "${jd2list}.tmp" && mv "${jd2list}.tmp" "$jd2list"
        log "Removed $shorthost from the server list."
    else
        log "$shorthost is not in the server list."
    fi
}
function changeserver {
    #
    deleteserver                                # check and remove the current server from the list
    nextserverhost=$( head -n 1 "$jd2list" )    # get the next server from the top of the list
    nextserver="${nextserverhost%%.*}"          # remove everything after the first '.'
    #
    if [[ "${nextserverhost,,}" == "eof" ]]; then
        connectnextcity
    else
        connectnextserver
    fi
}
function connectnextcity {
    getnextcity
    log "Server list is empty. Connecting to $nextcity." "NOTIFY"
    #
    if ! nordvpn connect "$nextcity"; then
        exitscript "2" "Connection to $nextcity failed. Exit."
    fi
    log "Connection successful."
    reloadapplet
    sleep 3
    updateserverlist
    deleteserver
}
function connectnextserver {
    log "Connect to the next server: $nextserver"
    #
    if ! nordvpn connect "$nextserver"; then
        if [[ "${removefailed,,}" == "y" ]]; then
            grep -v "$nextserverhost" "$jd2list" > "${jd2list}.tmp" && mv "${jd2list}.tmp" "$jd2list"
            log "Connect fail. Removed $nextserver from the server list."
        fi
        exitscript "2" "Connection to $nextserver failed. Exit."
    fi
    log "Connection successful."
    reloadapplet
    deleteserver
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
function reloadapplet {
    # reload Cinnamon Desktop applets
    if [[ "${nordlistapplet,,}" == "y" ]] && [[ -d "/home/$USER/.local/share/cinnamon/applets/nordlist_tray@ph202107" ]]; then
        # reload 'nordlist_tray@ph202107' - changes the icon color (for connection status) immediately.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'nordlist_tray@ph202107' string:'APPLET'
    fi
    if [[ "${nmapplet,,}" == "y" ]]; then
        # reload 'network@cinnamon.org' - removes extra 'nordlynx' entries.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'network@cinnamon.org' string:'APPLET'
    fi
}
function quiettime {
    # 0 = yes it's quiet time
    # 1 = no it's not quiet time
    #
    if [[ "${quietmode,,}" != "y" ]]; then
        return 1
    fi
    # force base 10
    local currenthour=$((10#$(date +%H)))
    local start=$((10#${quietstart:-0}))
    local end=$((10#${quietend:-0}))
    #
    if (( start > end )); then  # overnight range eg 22 to 08
        (( currenthour >= start || currenthour < end )) && return 0
    else  # same-day range eg. 09 to 17
        (( currenthour >= start && currenthour < end )) && return 0
    fi
    return 1
}
function makenoise {
    # $1 = "success" or "error"
    alert="${1:-error}"
    #
    case "${alertplay,,}" in
        y)  ;;  # continue
        s)  [[ "$alert" == "error" ]] && return;;
        e)  [[ "$alert" == "success" ]] && return;;
        *)  return;;    # (n, empty, typos)
    esac
    #
    alertsound="$alerterror"
    if [[ "$alert" == "success" ]]; then
        alertsound="$alertsuccess"
    fi
    #
    if [[ ! -f "$alertsound" ]]; then
        log "$alertsound not found." "WARNING"
        return
    fi
    #
    if quiettime; then
        return
    fi
    #
    # try PulseAudio, PipeWire, ffmpeg, terminal bell
    if command -v paplay >/dev/null; then
        pa_vol=$(( 65536 * alertvolume / 100 ))         # PulseAudio volume 0 to 65536
        timeout 2s paplay --volume="$pa_vol" "$alertsound" >/dev/null 2>&1 &    # background
        #
    elif command -v pw-play >/dev/null; then
        if [[ "$alertvolume" -eq 100 ]]; then
            pw_vol="1.0"
        else
            pw_vol=$(printf "0.%02d" "$alertvolume")    # PipeWire volume 0.0 to 1.0
        fi
        timeout 2s pw-play --volume="$pw_vol" "$alertsound" >/dev/null 2>&1 &
        #
    elif command -v ffplay >/dev/null; then
        timeout 2s ffplay -nodisp -autoexit -volume "$alertvolume" "$alertsound" >/dev/null 2>&1 &
        #
    else
        echo -ne "\a"   # terminal bell
    fi
}
function exitscript {
    exit_code="${1:-0}"
    exit_message="$2"
    #
    # 0 = success (default)
    # 1 = general error
    # 2 = connection error, reloadapplet
    #
    case "$exit_code" in
        0)  [[ -n "$exit_message" ]] && log "$exit_message" "RECONNECT"
            makenoise "success"
            ;;
        1)  [[ -n "$exit_message" ]] && log "$exit_message" "ERROR"
            makenoise "error"
            ;;
        2)  [[ -n "$exit_message" ]] && log "$exit_message" "ERROR"
            reloadapplet
            makenoise "error"
            ;;
        *)  log "${exit_message:-Script exited with unexpected code: $exit_code}" "ERROR"
            makenoise "error"
            ;;
    esac
    #
    if quiettime && [[ "${alertplay,,}" != "n" || "${notifications,,}" == "y" ]]; then
        log "Quiet Mode Active (${quietstart}:00-${quietend}:00)" "NOTIFY"
    fi
    # cleanup any leftover .tmp files
    [[ -f "${jd2list}.tmp" ]] && rm -f "${jd2list}.tmp"
    [[ -f "${logfile}.tmp" ]] && rm -f "${logfile}.tmp"
    # if terminated, kill any 'sleep' processes that are children of this script
    pkill -P $$ -x "sleep" >/dev/null 2>&1
    #
    exit "$exit_code"
}
#
# =====================================================================
#
# run exitscript if the script is interrupted or terminated, eg. user CTRL-C
trap 'exitscript 1 "Script terminated by system/user."' SIGINT SIGTERM
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
exitscript "0" "VPN: $currentcity $shorthost  List: $servercount  Next: $nextcity"
#
# eg. "VPN: New_York us8369  List: 13  Next: Los_Angeles"
# "VPN: New_York us8369" == The current VPN connection, city and server number.
# "List: 13" == The number of servers that are in the server list.
# "Next: Los_Angeles" == When the server list is empty, connect to this city next.
#
