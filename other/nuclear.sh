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
#nord_version="nordvpn=3.18.0"      # 09 May 2024 Tray icon. Fix Meshnet Routing kill switch.
#nord_version="nordvpn=3.18.1"      # 10 May 2024 Fix potential security vulnerabilities. Allowlist issue: https://github.com/NordSecurity/nordvpn-linux/issues/406
#nord_version="nordvpn=3.18.2"      # 11 Jun 2024 Fix allowlist and lan-discovery. Option to disable Tray. Snapstore available. Allowlist issue: https://github.com/NordSecurity/nordvpn-linux/issues/461
#nord_version="nordvpn=3.18.3"      # 22 Jul 2024 Bug fixes. Option to disable virtual locations. Allowlist issue:  https://github.com/NordSecurity/nordvpn-linux/issues/512
#nord_version="nordvpn=3.18.4"      # 19 Aug 2024 Bug fixes - routing, tray, dedicated-ip, gateway, allowlist.
#nord_version="nordvpn=3.18.5"      # 05 Sep 2024 Internal changes.
#nord_version="nordvpn=3.19.0"      # 30 Sep 2024 Post-Quantum VPN added.
#nord_version="nordvpn=3.19.1"      # 18 Nov 2024 Bugfixes. Meshnet fileshare library changed.
#nord_version="nordvpn=3.19.2"      # 27 Nov 2024 OpenVPN bugfix.
#nord_version="nordvpn=3.20.0"      # 21 Jan 2025 Significant security improvements. NordWhisper technology added.
#nord_version="nordvpn=3.20.1"      # 20 Mar 2025 Kill Switch, LAN-Discovery, general improvements. NordWhisper log messages fix.
#nord_version="nordvpn=3.20.2"      # 29 Apr 2025 Bug fixes.
#nord_version="nordvpn=3.20.3"      # 11 Jun 2025 Bug fixes: postquantum, firewall, allowlist, autoconnect.
#
# Login using a token, or leave blank to log in using a web browser.
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
    reload_applet
    linecolor "cyan" "nordvpn logout --persist-token"
    nordvpn logout --persist-token
    sudo systemctl stop nordvpnd.service
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
function reload_applet {
    # reload the Nordlist Applet to change the icon color immediately
    if [[ -d "/home/$USER/.local/share/cinnamon/applets/nordlist_tray@ph202107" ]]; then
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'nordlist_tray@ph202107' string:'APPLET'
    fi
}
function edit_script {
    # check for a default editor otherwise use nano
    if [[ -n "$VISUAL" ]]; then editor="$VISUAL"
    elif [[ -n "$EDITOR" ]]; then editor="$EDITOR"
    else editor="nano"
    fi
    "$editor" "$0"
    exit
}
#
# =====================================================================
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
#
case "$REPLY" in
    [Ee])
        edit_script
        ;;
    [Yy])
        trashnord
        installnord
        loginnord
        changelog
        default_settings
        ;;
    *)
        linebreak
        linecolor "red" "*** ABORT ***"
        echo
        ;;
esac
#
linebreak "nordvpn settings"
nordvpn settings
linebreak "nordvpn status"
nordvpn status
linebreak "\n$(linecolor "green" "Completed \u2705")" # unicode checkmark
nordvpn --version
linebreak
reload_applet
#
# Alternate install method:
#  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
