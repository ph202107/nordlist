#!/bin/bash
#
# Simple script to test NordVPN https and socks5 proxy servers.
# Uses 'curl' via the proxy to retrieve the external IP information.
#
# Nord Service Credentials (required)
# https://my.nordaccount.com - Services - NordVPN - Manual Setup
user=""
pass=""
#
# Choose "socks5" or "https"
protocol="socks5"
#
# Returns the external IP and geolocation info
site="https://ipinfo.io/"
#
#
function config_https {
    port="89"
    proxylist+=(
        # Add https proxy servers here
        # Almost all the VPN servers will handle https proxy
        # Format: "<location><space><server>"
        "Chicago us9892.nordvpn.com"
        "Seattle us9986.nordvpn.com"
        "Atlanta us8041.nordvpn.com"
        "Denver us5079.nordvpn.com"
        "Vancouver ca1586.nordvpn.com"
    )
}
function config_socks5 {
    port="1080"
    # Choose one or both for the socks5 proxylist
    socks5_proxies
    socks5_individual
}
function socks5_proxies {
    proxylist+=(
        # https://support.nordvpn.com/1087802472
        amsterdam.nl.socks.nordhold.net
        atlanta.us.socks.nordhold.net
        dallas.us.socks.nordhold.net
        los-angeles.us.socks.nordhold.net
        nl.socks.nordhold.net
        se.socks.nordhold.net
        stockholm.se.socks.nordhold.net
        us.socks.nordhold.net
        new-york.us.socks.nordhold.net
    )
}
function socks5_individual {
    proxylist+=(
        # List retrieved via NordVPN Public API on January 2, 2024
        # Subject to change
        socks-nl1.nordvpn.com
        socks-nl2.nordvpn.com
        socks-nl3.nordvpn.com
        socks-nl4.nordvpn.com
        socks-nl5.nordvpn.com
        socks-nl6.nordvpn.com
        socks-nl7.nordvpn.com
        socks-nl8.nordvpn.com
        socks-se8.nordvpn.com
        socks-se9.nordvpn.com
        socks-se10.nordvpn.com
        socks-se11.nordvpn.com
        socks-se12.nordvpn.com
        socks-se13.nordvpn.com
        socks-se14.nordvpn.com
        socks-se15.nordvpn.com
        socks-se16.nordvpn.com
        socks-se17.nordvpn.com
        socks-se18.nordvpn.com
        socks-se19.nordvpn.com
        socks-se20.nordvpn.com
        socks-se21.nordvpn.com
        socks-se22.nordvpn.com
        socks-se23.nordvpn.com
        socks-us1.nordvpn.com
        socks-us2.nordvpn.com
        socks-us3.nordvpn.com
        socks-us7.nordvpn.com
        socks-us8.nordvpn.com
        socks-us9.nordvpn.com
        socks-us10.nordvpn.com
        socks-us11.nordvpn.com
        socks-us12.nordvpn.com
        socks-us13.nordvpn.com
        socks-us14.nordvpn.com
        socks-us15.nordvpn.com
        socks-us27.nordvpn.com
        socks-us28.nordvpn.com
        socks-us29.nordvpn.com
        socks-us30.nordvpn.com
        socks-us31.nordvpn.com
        socks-us32.nordvpn.com
        socks-us33.nordvpn.com
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
#
proxylist=()
if [[ "${protocol}" == "socks5" ]]; then
    config_socks5
elif [[ "${protocol}" == "https" ]]; then
    config_https
fi
proxylist+=( "Exit" )
#
clear -x
echo
linecolor "green" "/// Test NordVPN Proxy ///"
echo
echo "Protocol= $(linecolor "yellow" "${protocol}")    Port= $(linecolor "yellow" "${port}")"
echo
PS3=$'\n''Choose a Server: '
select proxy in "${proxylist[@]}"
do
    if [[ "${proxy}" == "Exit" ]]; then
        echo
        exit
    elif (( 1 <= REPLY )) && (( REPLY <= ${#proxylist[@]} )); then
        if [[ "${protocol}" == "https" ]]; then
            location="$( echo "${proxy}" | cut -f1 -d' ' )"
            proxy="$( echo "${proxy}" | cut -f2 -d' ' )"
        else
            location="$( echo "${proxy}" | cut -f1 -d'.' )"
        fi
        echo
        linecolor "cyan" "ping -c 3 ${proxy}"
        echo
        ping -c 3 "${proxy}"
        echo
        linecolor "cyan" "curl --verbose --proxy ${protocol}://${proxy}:${port} --proxy-user ${user}:${pass} --location ${site}"
        echo
        curl --verbose --proxy "${protocol}://${proxy}:${port}" --proxy-user "${user}:${pass}" --location "${site}"
        echo
        echo
        echo "${location}"
        linecolor "yellow" "${protocol}://${proxy}:${port}"
        linecolor "green" "${protocol}://${user}:${pass}@${proxy}:${port}"
        echo
    else
        echo
        linecolor "red" "Invalid Option"
        echo
    fi
done
# System config
# https://forums.linuxmint.com/viewtopic.php?t=406463&sid=62c8a059e47b84548486020ee85354d1
