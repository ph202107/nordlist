#!/bin/bash
#
# Basic script to upgrade, reinstall, or downgrade the NordVPN client.
#
# Only tested on Linux Mint 20.3.  The script flushes iptables and
# deletes directories, review carefully before use.  Do not use.
#
# Choose the NordVPN app version to install
# List available versions with: "apt list -a nordvpn"
#
nord_version="nordvpn"              # install the latest version available
#nord_version="nordvpn=3.13.0"      # 23 May 2022 firewall - filter packets by firewall marks
#nord_version="nordvpn=3.14.0"      # 01 Jun 2022 CyberSec changed to "Threat Protection Lite"
#nord_version="nordvpn=3.14.1"      # 13 Jun 2022 Fix for app freezing
#nord_version="nordvpn=3.14.2"      # 28 Jul 2022 Works on Ubuntu 18.04, Mint 19.3
#nord_version="nordvpn=3.15.0"      # 17 Oct 2022 Added login token, routing, fwmark, analytics
#nord_version="nordvpn=3.15.1"      # 28 Nov 2022 Fix for older distros. Changes to "nordvpn status"
#nord_version="nordvpn=3.15.2"      # 06 Dec 2022 Fix for meshnet unavailable
#nord_version="nordvpn=3.15.3"      # 28 Dec 2022 Fix for crash after suspend
#nord_version="nordvpn=3.15.4"      # 26 Jan 2023 Faster meshnet connections
#
# v3.15.0+ can login using a token. Leave blank for earlier versions.
# To create a token visit https://my.nordaccount.com/
# Services - NordVPN - Access Token - Generate New Token
logintoken=""
#
nordchangelog="/usr/share/doc/nordvpn/changelog.gz"
#
#
function default_settings {
    lbreak "Apply Default Settings"
    #
    # After installation is complete, these settings will be applied
    #
    #nordvpn set technology nordlynx
    #nordvpn set protocol UDP
    #nordvpn set firewall enabled
    #nordvpn set routing enabled
    #nordvpn set analytics disabled
    #nordvpn set killswitch disabled
    #nordvpn set threatprotectionlite disabled
    #nordvpn set obfuscate disabled
    #nordvpn set notify disabled
    #nordvpn set autoconnect disabled
    #nordvpn set ipv6 disabled
    #nordvpn set dns disabled
    #nordvpn set meshnet enabled; wait
    #nordvpn set meshnet disabled; wait
    #nordvpn whitelist add subnet 192.168.1.0/24
    #
    #echo; nordvpn connect
    #
    wait
}
function lbreak {
    # break up wall of text
    echo
    echo -e "${LYellow}==========================="
    echo -e "$1${Color_Off}"
    echo
}
function trashnord {
    lbreak "Password"
    sudo echo "OK"
    lbreak "Quit Nord & Stop Service"
    nordvpn set killswitch disabled
    nordvpn disconnect
    nordvpn logout
    wait
    sudo systemctl stop nordvpnd.service
    sudo systemctl stop nordvpn.service
    wait
    lbreak "Flush iptables"
    flushtables
    lbreak "Purge nordvpn"
    sudo apt autoremove --purge nordvpn* -y
    lbreak "Remove Folders"
    # ====================================
    sudo rm -rf -v /var/lib/nordvpn
    sudo rm -rf -v /var/run/nordvpn
    rm -rf -v "/home/$USER/.config/nordvpn"
    # ====================================
}
function installnord {
    lbreak "Add Repo"
    if [[ -e /etc/apt/sources.list.d/nordvpn.list ]]; then
        echo -e "${LGreen}NordVPN repository found.${Color_Off}"
    else
        echo -e "${LGreen}Adding the NordVPN repository.${Color_Off}"
        echo
        cd "/home/$USER/Downloads" || exit
        wget -nc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
        echo
        sudo apt install "/home/$USER/Downloads/nordvpn-release_1.0.0_all.deb" -y
        # or: sudo dpkg -i "/home/$USER/Downloads/nordvpn-release_1.0.0_all.deb" -y
    fi
    lbreak "Apt Update"
    sudo apt update
    lbreak "Install $nord_version"
    sudo apt install $nord_version -y
    wait
}
function loginnord {
    lbreak "Check Group"
    if id -nG "$USER" | grep -qw "nordvpn"; then
        echo -e "${LGreen}$USER belongs to the 'nordvpn' group${Color_Off}"
    else
        # for first-time installation (might also require reboot)
        echo -e "${BRed}$USER does not belong to the 'nordvpn' group${Color_Off}"
        echo -e "${LGreen}sudo usermod -aG nordvpn $USER ${Color_Off}"
        sudo usermod -aG nordvpn "$USER"
        echo "(May need to logout or reboot)"
    fi
    lbreak "Check Service"
    if systemctl is-active --quiet nordvpnd; then
        echo -e "${LGreen}nordvpnd.service is active${Color_Off}"
    else
        echo -e "${LGreen}Starting the service... ${Color_Off}"
        echo "sudo systemctl start nordvpnd.service"
        sudo systemctl start nordvpnd.service; wait
    fi
    lbreak "Login"
    if [[ -n $logintoken ]]; then
        nordvpn login --token "$logintoken"
        wait
    else
        nordvpn login
        #nordvpn login --legacy
        #nordvpn login --username <username> --password <password>
        echo
        read -n 1 -r -p "Press any key after login is complete... "; echo
    fi
}
function flushtables {
    sudo iptables -S
    echo -e "${BRed}** Flush **${Color_Off}"
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
echo -e "${BRed}"
if command -v figlet &> /dev/null; then
    figlet -f slant NUCLEAR
else
    echo "///  NUCLEAR   ///"
fi
echo -e "${Color_Off}"
echo -e "${LGreen}Currently installed:${Color_Off}"
nordvpn --version
echo
echo -e "${LGreen}Version to install:${Color_Off}"
if [[ "$nord_version" == "nordvpn" ]]; then
    echo "$nord_version  (latest available)"
else
    echo "$nord_version"
fi
echo
echo
read -n 1 -r -p "Go nuclear? (y/n) "; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    trashnord
    installnord
    loginnord
    default_settings
    lbreak "Changelog"
    zcat "$nordchangelog" | head -n 15
else
    lbreak
    echo -e "${BRed}*** ABORT ***${Color_Off}"
    echo
fi
lbreak "nordvpn settings"
nordvpn settings
lbreak "nordvpn status"
nordvpn status
lbreak "\n${LGreen}Completed \u2705" # unicode checkmark
nordvpn --version
lbreak
#
# Alternate install method:
#  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
# On subsequent reinstalls the repository won't be removed
#
# https://nordvpn.com/blog/nordvpn-linux-release-notes/
# https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/
