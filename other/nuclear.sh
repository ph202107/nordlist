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
nord_version="nordvpn"              # install the latest version available
#nord_version="nordvpn=3.12.0-1"    # 03 Nov 2021 login via Nord Account
#nord_version="nordvpn=3.12.1-1"    # 18 Nov 2021
#nord_version="nordvpn=3.12.2"      # 16 Dec 2021
#nord_version="nordvpn=3.12.3"      # 11 Jan 2022
#nord_version="nordvpn=3.12.4"      # 10 Feb 2022
#nord_version="nordvpn=3.12.5"      # 14 Mar 2022 switched to policy-based traffic routing
#nord_version="nordvpn=3.13.0"      # 23 May 2022 firewall - filter packets by firewall marks
#nord_version="nordvpn=3.14.0"      # 01 Jun 2022 CyberSec changed to "Threat Protection Lite"
#nord_version="nordvpn=3.14.1"      # 13 Jun 2022
#nord_version="nordvpn=3.14.2"      # 28 Jul 2022
#
# list version numbers:
#   apt list -a nordvpn
#
# repo: https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/
#
function default_settings {
    lbreak
    # After installation is complete, these settings will be applied
    #
    #nordvpn set technology nordlynx
    #nordvpn set protocol UDP
    #nordvpn set firewall enabled
    #nordvpn set killswitch disabled
    #nordvpn set threatprotectionlite disabled
    #nordvpn set obfuscate disabled
    #nordvpn set notify disabled
    #nordvpn set autoconnect disabled
    #nordvpn set ipv6 disabled
    #nordvpn set dns disabled
    nordvpn set meshnet enabled
    wait
    nordvpn whitelist add subnet 192.168.1.0/24
    wait
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
    nordvpn logout
    wait
    sudo systemctl stop nordvpnd.service
    sudo systemctl stop nordvpn.service
    wait
    lbreak
    flushtables
    lbreak
    sudo apt autoremove --purge nordvpn* -y
    lbreak
    # ====================================
    sudo rm -rf -v /var/lib/nordvpn
    sudo rm -rf -v /var/run/nordvpn
    rm -rf -v "/home/$USER/.config/nordvpn"
    # ====================================
}
function installnord {
    lbreak
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
    lbreak
    sudo apt update
    lbreak
    sudo apt install $nord_version -y
    wait
}
function loginnord {
    lbreak
    if id -nG "$USER" | grep -qw "nordvpn"; then
        echo -e "${LGreen}$USER belongs to the 'nordvpn' group${Color_Off}"
        lbreak
    else
        # for first-time installation (might also require reboot)
        echo -e "${BRed}$USER does not belong to the 'nordvpn' group${Color_Off}"
        echo -e "${LGreen}sudo usermod -aG nordvpn $USER ${Color_Off}"
        sudo usermod -aG nordvpn "$USER"
        echo "(May need to logout or reboot)"
        lbreak
    fi
    if ! systemctl is-active --quiet nordvpnd; then
        echo -e "${LGreen}Starting the service... ${Color_Off}"
        echo "sudo systemctl start nordvpnd.service"
        sudo systemctl start nordvpnd.service; wait
        lbreak
    fi
    nordvpn login
    #nordvpn login --legacy
    #nordvpn login --username <username> --password <password>
    echo
    read -n 1 -r -p "Press any key after login is complete... "; echo
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
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    trashnord
    installnord
    loginnord
    default_settings
else
    lbreak
    echo -e "${BRed}** ABORT **${Color_Off}"
fi
lbreak
nordvpn settings
lbreak
nordvpn status
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
# https://nordvpn.com/blog/nordvpn-linux-release-notes/
# https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/
