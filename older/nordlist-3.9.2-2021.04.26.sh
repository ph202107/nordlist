#!/bin/bash
#
connected=$(nordvpn status | grep Status | cut -f2 -d':')
server=$(nordvpn status | grep server | cut -f3 -d' ' | cut -f1 -d'.')
country=$(nordvpn status | grep Country | cut -f2 -d':')
city=$(nordvpn status | grep City | cut -f2 -d':')
ip=$(nordvpn status | grep IP | cut -f4 -d' ')
technology=$(nordvpn status | grep technology | cut -f3 -d' ')
protocol=$(nordvpn status | grep protocol | cut -f3 -d' ')
uptime=$(nordvpn status | grep Uptime | cut -f 1-5 -d' ')
#
function logo {
cat << "EOF"
 _   _               ___     ______  _   _ 
| \ | | ___  _ __ __| \ \   / /  _ \| \ | |
|  \| |/ _ \| '__/ _` |\ \ / /| |_) |  \| |
| |\  | (_) | | | (_| | \ V / |  __/| |\  |
|_| \_|\___/|_|  \__,_|  \_/  |_|   |_| \_|

EOF
#
echo $connected: $city $country $server \($technology $protocol\)
echo $uptime IP: $ip
echo
}
function discon {
    echo 
    echo "Option $REPLY - Connect to $opt"
    echo
    echo "Disconnect"
    echo 
    nordvpn disconnect && 
    echo
    echo "Connect to $opt"
    echo
}
function status {
    echo
    nordvpn settings
    echo
    nordvpn status 
    echo
    # logo
    # date
    # notify-send "VPN connection established" "Connected to $opt"
}
#
clear
logo
#
PS3=$'\n''Connect to: '
#
options=("Vancouver" "Toronto" "Montreal" "Canada-Best" "USA" "Mexico" "UK" "France" "Germany" "Sweden" "Discord" "Restart" "Disconnect" "Exit")
#
select opt in "${options[@]}"
do
    case $opt in
        "Vancouver")
            discon
            nordvpn connect Canada Vancouver
            status
            break
            ;;
        "Toronto")
            discon
            nordvpn connect Canada Toronto
            status
            break
            ;;
        "Montreal")
            discon
            nordvpn connect Canada Nontreal
            status
            break
            ;;
        "Canada-Best")
            discon
            nordvpn connect Canada
            status
            break
            ;;
        "USA")
            discon
            nordvpn connect United_States
            status
            break
            ;;
        "Mexico")
            discon
            nordvpn connect Mexico
            status
            break
            ;;
        "UK")
            discon
            nordvpn connect United_Kingdom
            status
            break
            ;;
        "France")
            discon
            nordvpn connect France
            status
            break
            ;;
        "Germany")
            discon
            nordvpn connect Germany
            status
            break
            ;;
        "Sweden")
            discon
            nordvpn connect Sweden
            status
            break
            ;;
        "Discord")
            #discon
            #echo
            echo
            #nordvpn connect 
            status
            #/usr/bin/firefox --new-window
            break
            ;;
        "Restart")
            echo
            echo "Option $REPLY - Restart nordvpnd service"
            echo
            echo "sudo service nordvpnd restart"
            echo
            sudo service nordvpnd restart 
            echo 
            echo "Please Wait..."
            echo
            for t in {10..1}
                do
                echo -n "$t "
                sleep 1
            done
            echo
            status
            break
            ;;
        "Disconnect")
            echo 
            echo "Option $REPLY - $opt"
            echo 
            nordvpn disconnect && 
            echo
            status
            break
            ;;
        "Exit")
            echo
            echo "Option $REPLY - Exit.  Goodbye!"
            echo
            status
            break
            ;;
        *) echo -e '\n'"** Invalid option: $REPLY";;
    esac
done
