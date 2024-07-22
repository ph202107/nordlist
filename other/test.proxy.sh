#!/bin/bash
#
# Simple script to test NordVPN https and socks5 proxy servers.
# Uses 'curl' via the proxy to retrieve the external IP information.
#
# NordVPN Service Credentials (required)
# These are not the same as the NordAccount email/password.
# https://my.nordaccount.com - Services - NordVPN - Manual Setup
user=""
pass=""
#
# Choose the proxy type. Enter "https" or "socks5"
protocol="socks5"
#
# Specify ports
https_port="89"     # default: 89
socks5_port="1080"  # default: 1080
#
# Returns the external IP and geolocation info
site="https://ipinfo.io/"
#
# Perform a file download speed test using curl. "y" or "n"
speedtest="n"
localfile="/dev/null"
remotefile="https://ash-speed.hetzner.com/100MB.bin"
#remotefile="https://ash-speed.hetzner.com/1GB.bin"
#remotefile="https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso"
#
#
function list_https {
    proxylist+=(
        # Add https proxy servers here
        # Almost all the NordVPN servers support https proxy
        # Format: "<server><space><location>"
        "us6574.nordvpn.com (Chicago)"
        "us6575.nordvpn.com (Chicago)"
        "us8243.nordvpn.com (Seattle)"
        "us8244.nordvpn.com (Seattle)"
        "us10147.nordvpn.com (Dallas)"
        "us10148.nordvpn.com (Dallas)"
        "us10507.nordvpn.com (Atlanta)"
        "us10508.nordvpn.com (Atlanta)"
        "us9201.nordvpn.com (Denver)"
        "us9202.nordvpn.com (Denver)"
        "ca1743.nordvpn.com (Vancouver)"
        "ca1744.nordvpn.com (Vancouver)"
    )
}
function list_socks5 {
    proxylist+=(
        # https://support.nordvpn.com/hc/en-us/articles/20195967385745
        "amsterdam.nl.socks.nordhold.net"
        "atlanta.us.socks.nordhold.net"
        "dallas.us.socks.nordhold.net"
        "los-angeles.us.socks.nordhold.net"
        "nl.socks.nordhold.net"
        "se.socks.nordhold.net"
        "stockholm.se.socks.nordhold.net"
        "us.socks.nordhold.net"
        "new-york.us.socks.nordhold.net"
        "san-francisco.us.socks.nordhold.net"
        "detroit.us.socks.nordhold.net"
        #
        # Server list retrieved via NordVPN Public API on 22 Jul 2024
        # Subject to change
        "socks-nl1.nordvpn.com (Amsterdam)"
        "socks-nl2.nordvpn.com (Amsterdam)"
        "socks-nl3.nordvpn.com (Amsterdam)"
        "socks-nl4.nordvpn.com (Amsterdam)"
        "socks-nl5.nordvpn.com (Amsterdam)"
        "socks-nl6.nordvpn.com (Amsterdam)"
        "socks-nl7.nordvpn.com (Amsterdam)"
        "socks-nl8.nordvpn.com (Amsterdam)"
        "socks-us10.nordvpn.com (Atlanta)"
        "socks-us27.nordvpn.com (Atlanta)"
        "socks-us7.nordvpn.com (Atlanta)"
        "socks-us8.nordvpn.com (Atlanta)"
        "socks-us9.nordvpn.com (Atlanta)"
        "socks-us1.nordvpn.com (Dallas)"
        "socks-us2.nordvpn.com (Dallas)"
        "socks-us3.nordvpn.com (Dallas)"
        "socks-us34.nordvpn.com (Detroit)"
        "socks-us35.nordvpn.com (Detroit)"
        "socks-us36.nordvpn.com (Detroit)"
        "socks-us37.nordvpn.com (Detroit)"
        "socks-us38.nordvpn.com (Detroit)"
        "socks-us39.nordvpn.com (Detroit)"
        "socks-us40.nordvpn.com (Detroit)"
        "socks-us41.nordvpn.com (Detroit)"
        "socks-us42.nordvpn.com (Detroit)"
        "socks-us43.nordvpn.com (Detroit)"
        "socks-us11.nordvpn.com (Los Angeles)"
        "socks-us12.nordvpn.com (Los Angeles)"
        "socks-us13.nordvpn.com (Los Angeles)"
        "socks-us14.nordvpn.com (Los Angeles)"
        "socks-us15.nordvpn.com (Los Angeles)"
        "socks-us28.nordvpn.com (New York)"
        "socks-us29.nordvpn.com (New York)"
        "socks-us30.nordvpn.com (New York)"
        "socks-us31.nordvpn.com (New York)"
        "socks-us32.nordvpn.com (New York)"
        "socks-us33.nordvpn.com (New York)"
        "socks-us44.nordvpn.com (San Francisco)"
        "socks-us45.nordvpn.com (San Francisco)"
        "socks-us46.nordvpn.com (San Francisco)"
        "socks-us47.nordvpn.com (San Francisco)"
        "socks-us48.nordvpn.com (San Francisco)"
        "socks-us49.nordvpn.com (San Francisco)"
        "socks-us50.nordvpn.com (San Francisco)"
        "socks-us51.nordvpn.com (San Francisco)"
        "socks-us52.nordvpn.com (San Francisco)"
        "socks-us53.nordvpn.com (San Francisco)"
        "socks-se10.nordvpn.com (Stockholm)"
        "socks-se11.nordvpn.com (Stockholm)"
        "socks-se12.nordvpn.com (Stockholm)"
        "socks-se13.nordvpn.com (Stockholm)"
        "socks-se14.nordvpn.com (Stockholm)"
        "socks-se15.nordvpn.com (Stockholm)"
        "socks-se16.nordvpn.com (Stockholm)"
        "socks-se17.nordvpn.com (Stockholm)"
        "socks-se18.nordvpn.com (Stockholm)"
        "socks-se19.nordvpn.com (Stockholm)"
        "socks-se20.nordvpn.com (Stockholm)"
        "socks-se21.nordvpn.com (Stockholm)"
        "socks-se22.nordvpn.com (Stockholm)"
        "socks-se23.nordvpn.com (Stockholm)"
        "socks-se24.nordvpn.com (Stockholm)"
        "socks-se8.nordvpn.com (Stockholm)"
        "socks-se9.nordvpn.com (Stockholm)"
    )
}
function linecolor {
    # echo colored text
    # $1=color  $2=text
    case $1 in
        "green")   echo -e "\033[0;92m$2\033[0m";;  # light green
        "yellow")  echo -e "\033[0;93m$2\033[0m";;  # light yellow
        "cyan")    echo -e "\033[0;96m$2\033[0m";;  # light cyan
        "red")     echo -e "\033[1;31m$2\033[0m";;  # bold red
    esac
}
function edit_script {
    # check for a default editor otherwise use nano
    if [[ -n "$VISUAL" ]]; then
        editor="$VISUAL"
    elif [[ -n "$EDITOR" ]]; then
        editor="$EDITOR"
    else
        editor="nano"
    fi
    "$editor" "$0"
    exit
}
#
if [[ -z "${user}" ]] || [[ -z "${pass}" ]]; then
    linecolor "red" "Missing user/pass credentials."
    exit
fi
#
proxylist=()
if [[ "${protocol,,}" == "https" ]]; then
    port="${https_port}"
    list_https
elif [[ "${protocol,,}" == "socks5" ]]; then
    port="${socks5_port}"
    list_socks5
else
    linecolor "red" "Invalid Protocol: ${protocol}"
    exit
fi
proxylist+=( "Edit Script" "Exit" )
#
clear -x
echo
linecolor "green" "/// Test NordVPN Proxy ///"
echo
echo "Protocol= $(linecolor "yellow" "${protocol}")    Port= $(linecolor "yellow" "${port}")"
echo
PS3=$'\n''Choose a Server: '
select xproxy in "${proxylist[@]}"
do
    if [[ "${xproxy}" == "Exit" ]]; then
        echo
        exit
    elif [[ "${xproxy}" == "Edit Script" ]]; then
        edit_script
        exit
    elif (( 1 <= REPLY )) && (( REPLY <= ${#proxylist[@]} )); then
        #
        proxy="$( echo "${xproxy}" | cut -f1 -d' ' )"
        location="$( echo "${xproxy}" | cut -f2- -d' ' )"
        #
        echo
        linecolor "cyan" "ping -c 3 ${proxy}"
        echo
        ping -c 3 "${proxy}"
        echo
        linecolor "cyan" "curl --proxy '${protocol}://${proxy}:${port}' --proxy-user '${user}:${pass}' --location '${site}'"
        echo
        curl --proxy "${protocol}://${proxy}:${port}" --proxy-user "${user}:${pass}" --location "${site}"
        echo
        echo
        echo "${location}"
        linecolor "yellow" "${protocol}://${proxy}:${port}"
        linecolor "green" "${protocol}://${user}:${pass}@${proxy}:${port}"
        echo
        echo "File download speed test:"
        linecolor "cyan" "curl --proxy '${protocol}://${user}:${pass}@${proxy}:${port}' --output '$localfile' '$remotefile'"
        echo
        if [[ "$speedtest" =~ ^[Yy]$ ]]; then
            linecolor "yellow" "(CTRL-C to quit)"
            echo
            curl --proxy "${protocol}://${user}:${pass}@${proxy}:${port}" --output "$localfile" "$remotefile"
            echo
        fi
    else
        echo
        linecolor "red" "Invalid Option"
        echo
    fi
done
# System config
# https://forums.linuxmint.com/viewtopic.php?t=406463&sid=62c8a059e47b84548486020ee85354d1
