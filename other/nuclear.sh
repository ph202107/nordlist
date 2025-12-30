#!/bin/bash
#
# Basic script to upgrade, reinstall, or downgrade the NordVPN CLI.
#
# Only tested on Linux Mint.
# This script deletes directories, review carefully before use.
#
# List available versions with: "apt list -a nordvpn"
#
available_versions=(    # these versions will be displayed on the selection menu
    "nordvpn"           # install the latest version available
    "nordvpn=4.1.0"     # 11 Sep 2025 Improved OpenVPN security, DNS NordWhisper fix, upgrades
    "nordvpn=4.1.1"     # 12 Sep 2025 Hotfix for .rpm installs
    "nordvpn=4.2.0"     # 14 Oct 2025 Meshnet retained. Upgraded libraries. Fixes for analytics, mangle table.
    "nordvpn=4.2.1"     # 29 Oct 2025 Fix for missing libxml2 during installation.
    "nordvpn=4.2.2"     # 11 Nov 2025 Fix for excessive logging.
    "nordvpn=4.2.3"     # 21 Nov 2025 Raised the maximum HTTP response limit.
    "nordvpn=4.3.0"     # 16 Dec 2025 Bug fixes, GUI and tray improvements.
    "nordvpn=4.3.1"     # 17 Dec 2025 Fix 4.3.0 service start. https://github.com/NordSecurity/nordvpn-linux/issues/1276
)
# Default choice for the version to install (first in the list).
install_version="${available_versions[0]}"
#
# Login using a token, leave blank to log in using a web browser, or specify a token later.
# To create a token visit https://my.nordaccount.com/ - NordVPN - Advanced settings - Access token
login_token=""
token_expires=""    # token expiry date (optional)
#
# Default option to run the "sudo apt update" command.  "y" or "n"
perform_apt_update="y"
#
nord_changelog="/usr/share/doc/nordvpn/changelog.Debian.gz"
#
#
function default_settings {
    linebreak "Apply Default Settings"
    #
    # After installation is complete, these settings will be applied.
    # Add or remove any nordvpn settings as you prefer.
    #
    nordvpn set analytics enabled       # enables 'user-consent'
    nordvpn set lan-discovery enabled
    nordvpn set tray disabled
    nordvpn set notify disabled
    nordvpn set virtual-location disabled
    #nordvpn set post-quantum enabled
    #nordvpn connect --group P2P United_States
    #nordvpn set killswitch enabled
    #
}
function linecolor {
    # echo a colored line of text
    # $1=color  $2=text
    case $1 in
        "green")    echo -e "\033[0;92m${2}\033[0m";;    # light green
        "yellow")   echo -e "\033[0;93m${2}\033[0m";;    # light yellow
        "cyan")     echo -e "\033[0;96m${2}\033[0m";;    # light cyan
        "purple")   echo -e "\033[0;95m${2}\033[0m";;    # light purple
        "red")      echo -e "\033[1;31m${2}\033[0m";;    # bold red
    esac
}
function linebreak {
    # break up wall of text
    echo
    linecolor "yellow" "==========================="
    linecolor "yellow" "$1"
    echo
}
function printascii {
    # $1 = color, $2 = text
    clear -x
    if [[ "$figlet_exists" == "true" ]]; then
        linecolor "$1" "$(figlet -f small "$2")"
    else
        echo
        linecolor "$1" "///   $2   ///"
        echo
    fi
}
function trashnord {
    linebreak "Password"
    sudo echo "OK"
    linebreak "Quit Nord & Stop Services"
    nordvpn set killswitch disabled
    nordvpn disconnect
    reload_applet
    linecolor "cyan" "nordvpn logout --persist-token"
    nordvpn logout --persist-token
    sudo systemctl stop nordvpnd.service
    sudo killall norduserd 2>/dev/null
    linebreak "Purge nordvpn"
    sudo apt autoremove --purge nordvpn -y
    linebreak "Remove Folders"
    # =================================================================
    sudo rm -rf -v "/var/lib/nordvpn"
    sudo rm -rf -v "/var/run/nordvpn"
    rm -rf -v "/home/$USER/.config/nordvpn"
    rm -rf -v "/home/$USER/.cache/nordvpn"
    # =================================================================
}
function installnord {
    linebreak "Add Repo"
    repo1="/etc/apt/sources.list.d/nordvpn.list"        # added by nord deb file
    repo2="/etc/apt/sources.list.d/nordvpn-app.list"    # added by nord install.sh script
    #
    if [[ -e "$repo1" && -e "$repo2" ]]; then
        linecolor "red" "Possible Conflict!"
        echo "$repo1"
        echo "$repo2"
        echo -e "If you receive $(linecolor "red" "'configured multiple times'") warnings during 'apt update'"
        echo "consider deleting one of the nordvpn repos.  For example:"
        linecolor "red" "sudo rm $repo1"
        echo
        echo
    fi
    if [[ -e "$repo1" || -e "$repo2" ]]; then
        linecolor "green" "NordVPN repository found."
    else
        linecolor "green" "Adding the NordVPN repository."
        echo
        download_path="/home/$USER/Downloads"
        #
        if ! cd "$download_path"; then
            linecolor "red" "$download_path not found"
            exit 1
        fi
        if ! wget -v -nc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn-release/nordvpn-release_1.0.0_all.deb; then
            linecolor "red" "Failed to download the package."
            exit 1
        fi
        echo
        if ! sudo apt install "${download_path}/nordvpn-release_1.0.0_all.deb" -y; then
            linecolor "red" "Failed to install the package."
            exit 1
        fi
    fi
    linebreak "Apt Update"
    if [[ "$perform_apt_update" =~ ^[Yy]$ ]]; then
        sudo apt update
    else
        linecolor "red" "(Skipped)"
    fi
    linebreak "Install $install_version"
    sudo apt install "$install_version" -y
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
        echo
        if ! sudo systemctl start nordvpnd.service; then
            linecolor "red" "Failed to start nordvpnd.service"
            echo
            exit 1
        fi
        timeout="10"
        count="0"
        success="false"
        echo -n "Waiting for service."
        while [[ "$count" -lt "$timeout" ]]
        do
            if systemctl is-active --quiet nordvpnd; then
                sleep 1     # pause in case service starts and stops
                if systemctl is-active --quiet nordvpnd; then
                    success="true"
                    break
                fi
            fi
            echo -n "."
            sleep 1
            ((count++))
        done
        echo
        if [[ "$success" = "true" ]]; then
            linecolor "green" "nordvpnd.service has started."
        else
            linecolor "red" "nordvpnd.service failed to start."
            echo
            linecolor "cyan" "sudo systemctl status nordvpnd.service"
            sudo systemctl status nordvpnd.service
            echo
            echo -e "View logs with: $(linecolor "cyan" "journalctl -u nordvpnd")"
            echo
            exit 1
        fi
    fi
    #
    linebreak "Disable Analytics"
    echo "Skip the user-consent prompt before login."
    echo "https://github.com/NordSecurity/nordvpn-linux/issues/958"
    echo "Refer to: https://my.nordaccount.com/legal/privacy-policy/"
    nordvpn set analytics disabled
    #
    if [[ -n $login_token ]]; then
        linebreak "Login (token)"
        nordvpn login --token "$login_token"
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
function changelog {
    linebreak "Changelog"
    linecolor "green" "$nord_changelog"
    echo
    zcat "$nord_changelog" | head -n 15
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
}
function choose_version {
    printascii "green" "VERSION"
    echo -e "$(linecolor "red" "Note:") 4.3.0 nordvpnd.service may not start after clean install."
    echo "(bug) https://github.com/NordSecurity/nordvpn-linux/issues/1276"
    echo
    PS3=$'\n''Choose a Version: '
    select choice in "${available_versions[@]}"
    do
        if (( 1 <= REPLY )) && (( REPLY <= ${#available_versions[@]} )); then
            install_version="$choice"
            break
        else
            linecolor "red" "Invalid Option"
        fi
    done
}
function add_token {
    printascii "yellow" "TOKEN"
    if [[ -n $login_token ]]; then
        linecolor "red" "Token cleared."
        echo
    fi
    login_token=""
    token_expires=""
    read -r -p "Enter the login token: " login_token
    if [[ -z $login_token ]]; then
        linecolor "red" "(No Token)"
    fi
}
function header {
    printascii "red" "NUCLEAR"
    echo -ne "$(linecolor "green" "Currently Installed: ")"
    echo "$current_version"
    echo
    echo -ne "$(linecolor "green" "Version to Install: ")"
    if [[ "${install_version,,}" == "nordvpn" ]]; then
        echo "$install_version (latest available)"
    else
        echo "$install_version"
    fi
    echo
    echo -ne "$(linecolor "yellow" "Login Token: ")"
    if [[ -n $login_token ]]; then
        echo "$login_token"
        if [[ -n $token_expires ]]; then
            echo
            echo -ne "$(linecolor "yellow" "Token Expires: ")"
            echo "$token_expires"
        fi
    else
        echo "No token. Log in with web browser."
    fi
    echo
    echo -ne "$(linecolor "purple" "Apt Update:") "
    if [[ "$perform_apt_update" =~ ^[Yy]$ ]]; then
        echo -e "\u2705"    # unicode checkmark
    else
        echo -e "\u274c"    # unicode X
    fi
    echo
    echo -e "Type $(linecolor "green" "V") to choose another version."
    echo -e "Type $(linecolor "yellow" "T") to add/remove a token."
    echo -e "Type $(linecolor "purple" "A") to enable/disable 'apt update'."
    echo -e "Type $(linecolor "cyan" "E") to edit the script."
    echo
    read -n 1 -r -p "Go nuclear? (y/n/V/T/A/E) "; echo
    echo
}
#
# =====================================================================
#
if [[ "$EUID" -eq 0 ]]; then
    linecolor "red" "Script should be run by the interactive user, not root."
    linecolor "red" "Run './nuclear.sh' instead of 'sudo ./nuclear.sh'."
    echo
    exit 1
fi
#
if command -v figlet &> /dev/null; then
    figlet_exists="true"
else
    figlet_exists="false"
fi
#
current_version="$(nordvpn --version)"
#
while true; do
    header
    case "$REPLY" in
        [Vv])
            choose_version
            ;;
        [Tt])
            add_token
            ;;
        [Aa])
            if [[ ! "$perform_apt_update" =~ ^[Yy]$ ]]; then
                perform_apt_update="y"
            else
                perform_apt_update="n"
            fi
            ;;
        [Ee])
            edit_script
            exit
            ;;
        [Yy])
            trashnord
            installnord
            loginnord
            changelog
            default_settings
            break
            ;;
        *)
            printascii "red" "ABORT"
            break
            ;;
    esac
done
#
linebreak "nordvpn settings"
nordvpn settings
linebreak "nordvpn status"
nordvpn status
linebreak "\n$(linecolor "green" "Completed \u2705")"
nordvpn --version
linebreak
reload_applet
#
# Alternate install method:
#   sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
# NordVPN GUI install;
#   sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh) -p nordvpn-gui
#
