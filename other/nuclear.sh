#!/bin/bash
#
# Basic script to upgrade, reinstall, or downgrade the NordVPN client.
#
# Only tested on Linux Mint.  The script flushes iptables and
# deletes directories, review carefully before use.  Do not use.
#
# Choose the NordVPN app version to install
# List available versions with: "apt list -a nordvpn"
#
nord_version="nordvpn"              # install the latest version available
#nord_version="nordvpn=3.14.2"      # 29 Jul 2022 Works on Ubuntu 18.04, Mint 19.3
#nord_version="nordvpn=3.15.0"      # 18 Oct 2022 Added login token, routing, fwmark, analytics.  Incompatible with Ubuntu 18.04, Mint 19.3
#nord_version="nordvpn=3.15.1"      # 28 Nov 2022 Fix for older distros. Changes to "nordvpn status".  Last version to work with Ubuntu 18.04, Mint 19.3
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
#nord_version="nordvpn=3.17.0"      # 16 Jan 2024 Meshnet peer rename, clear transfer history. DNS leak issue: https://github.com/NordSecurity/nordvpn-linux/issues/243
#nord_version="nordvpn=3.17.1"      # 12 Feb 2024 /etc/resolv.conf DNS fix, bug fixes. IPv6 issue: https://github.com/NordSecurity/nordvpn-linux/issues/243
#nord_version="nordvpn=3.17.2"      # 14 Feb 2024 bug fix for IPv6 issue in 3.17.1
#nord_version="nordvpn=3.17.3"      # 28 Mar 2024 Fixed meshnet routing and OpenVPN. DNS leak issue: https://github.com/NordSecurity/nordvpn-linux/issues/343
#nord_version="nordvpn=3.17.4"      # 05 Apr 2024 Fixed DNS leak in 3.17.3. Lan-discovery issue: https://github.com/NordSecurity/nordvpn-linux/issues/371
#nord_version="nordvpn=3.18.0"      # 09 May 2024 Tray icon. Fix Meshnet Routing kill switch.
#nord_version="nordvpn=3.18.1"      # 10 May 2024 Fix potential security vulnerabilities. Allowlist issue: https://github.com/NordSecurity/nordvpn-linux/issues/406
#nord_version="nordvpn=3.18.2"      # 11 Jun 2024 Fix allowlist and lan-discovery. Option to disable Tray. Snapstore available. Allowlist issue: https://github.com/NordSecurity/nordvpn-linux/issues/461
#nord_version="nordvpn=3.18.3"      # 22 Jul 2024 Bug fixes. Option to disable virtual locations. Allowlist issue:  https://github.com/NordSecurity/nordvpn-linux/issues/512
#nord_version="nordvpn=3.18.4"      # 19 Aug 2024 Bug fixes - routing, tray, dedicated-ip, gateway, allowlist.
#nord_version="nordvpn=3.18.5"      # 05 Sep 2024 Internal changes.
#nord_version="nordvpn=3.19.0"      # 30 Sep 2024 Post-Quantum VPN added.
#nord_version="nordvpn=3.19.1"      # 19 Nov 2024 Bugfixes. Meshnet fileshare library changed.
#
# v3.15.0+ can login using a token. Leave blank for earlier versions.
# To create a token visit https://my.nordaccount.com/ - Services - NordVPN - Manual Setup - Generate New Token
logintoken=""
expires="Permanent"
#
nordchangelog="/usr/share/doc/nordvpn/changelog.Debian.gz"
#
#
function default_settings {
    linebreak "Apply Default Settings"
    #
    # After installation is complete, these settings will be applied
    #
    #nordvpn set lan-discovery enabled
    #nordvpn set tray disabled
    #nordvpn set notify disabled
    #nordvpn set virtual-location disabled
    #nordvpn set post-quantum enabled
    #nordvpn connect --group P2P United_States
    #nordvpn set killswitch enabled
    #
}
function linecolor {
    # echo a colored line of text
    # $1=color  $2=text
    case $1 in
        "green")   echo -e "\033[0;92m${2}\033[0m";;  # light green
        "yellow")  echo -e "\033[0;93m${2}\033[0m";;  # light yellow
        "cyan")    echo -e "\033[0;96m${2}\033[0m";;  # light cyan
        "red")     echo -e "\033[1;31m${2}\033[0m";;  # bold red
    esac
}
function linebreak {
    # break up wall of text
    echo
    linecolor "yellow" "==========================="
    linecolor "yellow" "$1"
    echo
}
function trashnord {
    linebreak "Password"
    sudo echo "OK"
    linebreak "Quit Nord & Stop Service"
    nordvpn set killswitch disabled
    nordvpn disconnect
    reload_cinnapplet
    if nordvpn logout --help | grep -q -i "persist-token"; then
        linecolor "cyan" "nordvpn logout --persist-token"
        nordvpn logout --persist-token
    else
        linecolor "cyan" "nordvpn logout"
        nordvpn logout
    fi
    wait
    sudo systemctl stop nordvpnd.service
    wait
    linebreak "Flush iptables"
    flushtables
    linebreak "Purge nordvpn"
    sudo apt autoremove --purge nordvpn -y
    linebreak "Remove Folders"
    # =================================================================
    sudo rm -rf -v "/var/lib/nordvpn"
    sudo rm -rf -v "/var/run/nordvpn"
    rm -rf -v "/home/$USER/.config/nordvpn"
    # =================================================================
}
function installnord {
    linebreak "Add Repo"
    if [[ -e /etc/apt/sources.list.d/nordvpn.list ]]; then
        linecolor "green" "NordVPN repository found."
    else
        linecolor "green" "Adding the NordVPN repository."
        echo
        cd "/home/$USER/Downloads" || exit
        wget -nc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn-release/nordvpn-release_1.0.0_all.deb
        echo
        sudo apt install "/home/$USER/Downloads/nordvpn-release_1.0.0_all.deb" -y
    fi
    linebreak "Apt Update"
    sudo apt update
    linebreak "Install $nord_version"
    sudo apt install $nord_version -y
    wait
}
function loginnord {
    linebreak "Check Group"
    if id -nG "$USER" | grep -qw "nordvpn"; then
        linecolor "green" "$USER belongs to the 'nordvpn' group"
    else
        # for first-time installation (might also require reboot)
        linecolor "red" "$USER does not belong to the 'nordvpn' group"
        linecolor "cyan" "Trying: sudo usermod -aG nordvpn $USER"
        sudo usermod -aG nordvpn "$USER"
        linecolor "yellow" "(May need to logout or reboot)"
    fi
    linebreak "Check Service"
    if systemctl is-active --quiet nordvpnd; then
        linecolor "green" "nordvpnd.service is active"
    else
        linecolor "green" "Starting the service..."
        linecolor "cyan" "Trying: sudo systemctl start nordvpnd.service"
        sudo systemctl start nordvpnd.service || exit
    fi
    if [[ -n $logintoken ]]; then
        linebreak "Login (token)"
        nordvpn login --token "$logintoken"
        wait
    else
        linebreak "Login (browser)"
        nordvpn login
        echo
        echo "Provide the Callback URL if necessary or"
        echo "just hit Enter after login is complete."
        echo
        read -r -p "Callback URL: "; echo
        echo
        if [[ -n $REPLY ]]; then
            linecolor "cyan" "nordvpn login --callback '$REPLY'"
            nordvpn login --callback "$REPLY"
            echo
        fi
    fi
    linebreak "Account"
    nordvpn account
}
function flushtables {
    linecolor "cyan" "iptables before:"
    sudo iptables -S
    echo
    linecolor "red" "*** Flush ***"
    echo
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
    linecolor "cyan" "iptables after:"
    sudo iptables -S
}
function changelog {
    linebreak "Changelog"
    linecolor "green" "$nordchangelog"
    echo
    zcat "$nordchangelog" | head -n 15
    echo
    linecolor "green" "https://nordvpn.com/blog/nordvpn-linux-release-notes/"
    linecolor "green" "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/"
}
function reload_cinnapplet {
    # reload the "bash-sensors" Cinnamon applet
    # changes the icon color for connection status immediately
    # does nothing if there is no applet or if it's not used with nordvpn
    #
    directory="/home/$USER/.cinnamon/configs/bash-sensors@pkkk"
    desktop_env="$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')"
    #
    # check if the directory exists and the Cinnamon Desktop is in use
    if [[ -d "$directory" ]] && [[ "$desktop_env" == *"cinnamon"* ]]; then
        # search for "nordvpn" within the config file
        if grep -rqi --include='*.json' "nordvpn" "$directory"; then
            # reload the applet
            dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'bash-sensors@pkkk' string:'APPLET'
        fi
    fi
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
clear -x
if command -v figlet &> /dev/null; then
    linecolor "red" "$(figlet -f slant NUCLEAR)"
else
    echo
    linecolor "red" "///  NUCLEAR   ///"
    echo
fi
echo
linecolor "green" "Currently installed:"
nordvpn --version
echo
linecolor "green" "Version to install:"
if [[ "$nord_version" == "nordvpn" ]]; then
    echo "$nord_version  (latest available)"
else
    echo "$nord_version"
fi
echo
linecolor "yellow" "Login Token:"
if [[ -n $logintoken ]]; then
    echo "$logintoken"
    echo
    linecolor "yellow" "Token Expires:"
    echo "$expires"
else
    echo "No token. Log in with web browser."
fi
echo
echo -e "Type $(linecolor "green" "E") to edit the script."
echo
echo
read -n 1 -r -p "Go nuclear? (y/n/E) "; echo
echo
if [[ $REPLY =~ ^[Ee]$ ]]; then
    edit_script
elif [[ $REPLY =~ ^[Yy]$ ]]; then
    trashnord
    installnord
    loginnord
    changelog
    default_settings
else
    linebreak
    linecolor "red" "*** ABORT ***"
    echo
fi
linebreak "nordvpn settings"
nordvpn settings
linebreak "nordvpn status"
nordvpn status
linebreak "\n$(linecolor "green" "Completed \u2705")" # unicode checkmark
nordvpn --version
linebreak
#
# function default_settings may contain a "connect" command
if [[ "$( nordvpn status | awk -F ': ' '/Status/{print tolower($2)}' )" == "connected" ]]; then
    reload_cinnapplet
fi
#
# Alternate install method:
#  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
