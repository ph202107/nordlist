#!/bin/bash
#
# Basic script to upgrade, reinstall, or downgrade the NordVPN client.
#
# Only tested on Linux Mint 21.1.  The script flushes iptables and
# deletes directories, review carefully before use.  Do not use.
#
# Choose the NordVPN app version to install
# List available versions with: "apt list -a nordvpn"
#
nord_version="nordvpn"              # install the latest version available
#nord_version="nordvpn=3.14.2"      # 29 Jul 2022 Works on Ubuntu 18.04, Mint 19.3
#nord_version="nordvpn=3.15.0"      # 18 Oct 2022 Added login token, routing, fwmark, analytics
#nord_version="nordvpn=3.15.1"      # 28 Nov 2022 Fix for older distros. Changes to "nordvpn status"
#nord_version="nordvpn=3.15.2"      # 06 Dec 2022 Fix for meshnet unavailable
#nord_version="nordvpn=3.15.3"      # 29 Dec 2022 Fix for crash after suspend
#nord_version="nordvpn=3.15.4"      # 26 Jan 2023 Faster meshnet connections
#nord_version="nordvpn=3.15.5"      # 20 Feb 2023 Fix for Meshnet connectivity issue
#nord_version="nordvpn=3.16.0"      # 13 Mar 2023 Additional Meshnet features
#nord_version="nordvpn=3.16.1"      # 28 Mar 2023 Fix for OpenVPN on Fedora
#nord_version="nordvpn=3.16.2"      # 26 Apr 2023 Legacy logins removed. Meshnet notifications
#nord_version="nordvpn=3.16.3"      # 01 Jun 2023 OpenVPN security upgrade.
#nord_version="nordvpn=3.16.4"      # 31 Jul 2023 Fix Port/subnet whitelist. Meshnet transfers
#nord_version="nordvpn=3.16.5"      # 02 Aug 2023 Fix for GOCOVERDIR error in 3.16.4
#nord_version="nordvpn=3.16.6"      # 18 Sep 2023 LAN Discovery added. Whitelist is now Allowlist
#nord_version="nordvpn=3.16.7"      # 31 Oct 2023 Improved help, fixed Meshnet high CPU
#nord_version="nordvpn=3.16.8"      # 14 Nov 2023 Improved Meshnet speeds
#nord_version="nordvpn=3.16.9"      # 06 Dec 2023 Minor tweaks and fixes
#
# v3.15.0+ can login using a token. Leave blank for earlier versions.
# To create a token visit https://my.nordaccount.com/
# Services - NordVPN - Manual Setup - Generate New Token
logintoken=""
expires="Permanent"
#
nordchangelog="/usr/share/doc/nordvpn/changelog.gz"
#
#
function default_settings {
    lbreak "Apply Default Settings"
    #
    # After installation is complete, these settings will be applied
    #
    #nordvpn set analytics disabled
    #nordvpn allowlist add subnet 192.168.1.0/24
    #
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
    if nordvpn logout --help | grep -q -i "persist-token"; then
        echo -e "${LGreen}(nordvpn logout --persist-token)${Color_Off}"
        nordvpn logout --persist-token
    else
        echo -e "${LGreen}(nordvpn logout)${Color_Off}"
        nordvpn logout
    fi
    wait
    sudo systemctl stop nordvpnd.service
    sudo systemctl stop nordvpn.service
    wait
    lbreak "Flush iptables"
    flushtables
    lbreak "Purge nordvpn"
    sudo apt autoremove --purge nordvpn -y
    lbreak "Remove Folders"
    # ======================================
    sudo rm -rf -v /var/lib/nordvpn
    sudo rm -rf -v /var/run/nordvpn
    rm -rf -v "/home/$USER/.config/nordvpn"
    # ======================================
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
        sudo systemctl start nordvpnd.service || exit
    fi
    if [[ -n $logintoken ]]; then
        lbreak "Login (token)"
        nordvpn login --token "$logintoken"
        wait
    else
        lbreak "Login (browser)"
        nordvpn login
        echo
        echo "Provide the Callback URL if necessary or"
        echo "just hit Enter after login is complete."
        echo
        read -r -p "Callback URL: "; echo
        echo
        if [[ -n $REPLY ]]; then
            nordvpn login --callback "$REPLY"
            echo
        fi
    fi
    lbreak "Account"
    nordvpn account
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
function changelog {
    lbreak "Changelog"
    echo -e "${LGreen}$nordchangelog${Color_Off}"
    echo
    zcat "$nordchangelog" | head -n 15
    echo
    echo -e "${LGreen}https://nordvpn.com/blog/nordvpn-linux-release-notes/${Color_Off}"
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
echo -e "${LYellow}Login Token:${Color_Off}"
if [[ -n $logintoken ]]; then
    echo "$logintoken"
    echo
    echo -e "${LYellow}Token Expires:${Color_Off}"
    echo "$expires"
else
    echo "No token. Log in with web browser."
fi
echo
echo
read -n 1 -r -p "Go nuclear? (y/n) "; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    trashnord
    installnord
    loginnord
    default_settings
    changelog
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
#
# https://nordvpn.com/blog/nordvpn-linux-release-notes/
# https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/
