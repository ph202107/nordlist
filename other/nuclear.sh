#!/bin/bash
#
# Basic script to reinstall or downgrade the NordVPN Linux client.
#
# Only tested on Linux Mint 20.3.  The script flushes iptables and
# deletes directories, review carefully before use.  Do not use.
#
# Choose the NordVPN app version to install
#   (uncomment one of the following)
#
nord_version="nordvpn"           # latest version
#nord_version="nordvpn=3.7.4"
#nord_version="nordvpn=3.8.10"
#nord_version="nordvpn=3.9.5-1"
#nord_version="nordvpn=3.10.0-1"
#nord_version="nordvpn=3.11.0-1"
#nord_version="nordvpn=3.12.0-1"
#nord_version="nordvpn=3.12.1-1"
#
# list version numbers:
#   apt-cache showpkg nordvpn
#   apt list -a nordvpn
#
function default_settings {
    lbreak
    # After installation is complete, these settings will be applied
    #
    nordvpn set technology nordlynx
    nordvpn whitelist add subnet 192.168.1.0/24
    #
    #
}
function lbreak {
    # break up wall of text
    echo
    echo -e "${LYellow}=========================${Color_Off}"
    echo
}
function trashnord {
    lbreak
    sudo echo "OK"
    lbreak
    nordvpn set killswitch disabled
    nordvpn disconnect
    sudo systemctl stop nordvpnd.service
    sudo systemctl stop nordvpn.service
    wait
    lbreak
    flushtables
    lbreak
    sudo apt autoremove --purge nordvpn* -y
    lbreak
    sudo rm -rf -v /var/lib/nordvpn     # should be gone already
    rm -rf -v ~/.config/nordvpn
}
function installnord {
    lbreak
    if [[ -e /etc/apt/sources.list.d/nordvpn.list ]]; then
        echo -e ${LGreen}"NordVPN repository found."${Color_Off}
    else
        echo -e ${LGreen}"Adding the NordVPN repository."${Color_Off}
        echo
        cd ~/Downloads
        wget -nc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
        echo
        echo
        sudo apt install ~/Downloads/nordvpn-release_1.0.0_all.deb -y
        # or: sudo dpkg -i ~/Downloads/nordvpn-release_1.0.0_all.deb -y
    fi
    lbreak
    sudo apt update
    lbreak
    sudo apt install $nord_version -y
    wait
}
function loginnord {
    lbreak
    if ! systemctl is-active --quiet nordvpnd; then
        echo -e "${LGreen}Starting the service... ${Color_Off}"
        echo "sudo systemctl start nordvpnd.service"
        sudo systemctl start nordvpnd.service; wait
        lbreak
    fi
    nordvpn login
    echo
    read -n 1 -r -p "Press any key after login is complete... "; echo
}
function flushtables {
    sudo iptables -S
    echo -e ${BRed}"** flush **"${Color_Off}
    # https://www.cyberciti.biz/tips/linux-iptables-how-to-flush-all-rules.html
    # Accept all traffic first to avoid ssh lockdown
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    # Flush All Iptables Chains/Firewall rules
    sudo iptables -F
    # Delete all Iptables Chains
    sudo iptables -X
    # Flush all counters
    sudo iptables -Z
    # Flush and delete all nat and  mangle
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    sudo iptables -t mangle -F
    sudo iptables -t mangle -X
    sudo iptables -t raw -F
    sudo iptables -t raw -X
    #
    sudo iptables -S
}
#
LYellow='\033[0;93m'
LGreen='\033[0;92m'
BRed='\033[1;31m'
Color_Off='\033[0m'
#
clear -x
echo -e ${BRed}
figlet -f slant NUCLEAR
echo -e ${Color_Off}
echo -e "${LGreen}Currently installed:${Color_Off}"
nordvpn --version
echo
echo -e "${LGreen}Version to install:${Color_Off}"
echo "$nord_version"
echo
echo
read -n 1 -r -p "Go nuclear? (y/n) "; echo
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    trashnord
    installnord
    loginnord
    default_settings
else
    lbreak
    echo -e ${BRed}"** ABORT **"${Color_Off}
fi
lbreak
nordvpn status
lbreak
nordvpn settings
lbreak
echo -e "${LGreen}Completed \u2705${Color_Off}" # unicode checkmark
echo
nordvpn --version
lbreak
#
# Alternate install method:
#  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
# On subsequent reinstalls the repository won't be removed
#
