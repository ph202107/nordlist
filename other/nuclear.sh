#!/bin/bash
#
# Basic script to upgrade, reinstall, or downgrade the NordVPN CLI and GUI.
# This script deletes directories, review carefully before use.
# Only tested on Linux Mint.
#
available_versions=(
    # These versions will be displayed on the selection menu.
    #=============================================================================|
    "nordvpn - Install the latest version available."
    "4.5.0 - 16 Mar 2026 Nordwhisper ECH, OpenSSL fix, NetworkManager, DNS."
    "4.6.0 - 20 Apr 2026 Fix DNS, logout, token, GUI changes, pause feature."
    "5.0.0 - 27 May 2026 Iptables to nftables, regional groups, GUI, allowlist."
)
#
# Default choice for the version to install, eg. "nordvpn" or "4.6.0"
app_version="nordvpn"
#
# Login using a token, leave blank to log in using a web browser, or specify a token later.
# To create a token visit https://my.nordaccount.com/ - NordVPN - Advanced settings - Access token
login_token=""
token_expires=""    # token expiry date (optional)
#
# Default option to run the "sudo apt update" command.  "y" or "n"
perform_apt_update="y"
#
# Location of the nordvpn changelog on your system.
nord_changelog="/usr/share/doc/nordvpn/changelog.Debian.gz"
#
# Where to download the .deb file if adding the repo.
download_path="$HOME/Downloads"
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
        "purple")   echo -e "\033[0;95m${2}\033[0m";;    # light purple
        "cyan")     echo -e "\033[0;96m${2}\033[0m";;    # light cyan
        "red")      echo -e "\033[1;31m${2}\033[0m";;    # bold red
    esac
}
function linebreak {
    # break up wall of text
    echo
    linecolor "yellow" "================================================="
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
    check_group # if 'add user' then exit
    linebreak "Quit Nord & Stop Services"
    if command -v nordvpn &> /dev/null; then
        timeout 3s nordvpn set killswitch disabled
        timeout 3s nordvpn disconnect
        linecolor "cyan" "nordvpn logout --persist-token"
        timeout 10s nordvpn logout --persist-token
    fi
    sudo timeout 5s systemctl stop nordvpnd.service 2>/dev/null
    sudo killall -9 nordvpn-gui nordvpn nordvpnd norduserd 2>/dev/null
    sleep 1
    reload_applet
    linebreak "Purge nordvpn-gui and nordvpn"
    sudo apt purge nordvpn-gui nordvpn -y
    sudo apt autoremove -y
    linebreak "Remove Folders"
    # ====================================================================
    [[ -d "/var/lib/nordvpn" ]] && sudo rm -rf -v "/var/lib/nordvpn"
    [[ -d "/var/run/nordvpn" ]] && sudo rm -rf -v "/var/run/nordvpn"
    [[ -d "$HOME/.config/nordvpn" ]] && rm -rf -v "$HOME/.config/nordvpn"
    [[ -d "$HOME/.cache/nordvpn" ]] && rm -rf -v "$HOME/.cache/nordvpn"
    # ====================================================================
}
function check_repo {
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
        return
    fi
    #
    linecolor "green" "Adding the NordVPN repository."
    echo
    if [[ ! -d "$download_path" ]]; then
        linecolor "red" "$download_path not found"
        exit 1
    fi
    debrepo="https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn-release"
    debfile="nordvpn-release_1.0.0_all.deb"
    debremote="${debrepo}/${debfile}"
    deblocal="${download_path}/${debfile}"
    #
    if ! wget -q --show-progress -O "${deblocal}" "${debremote}"; then
        linecolor "red" "Failed to download the package."
        exit 1
    fi
    if [[ ! -s "${deblocal}" ]]; then
        linecolor "red" "${deblocal} is missing or empty."
        exit 1
    fi
    if ! sudo apt install "${deblocal}" -y; then
        linecolor "red" "Failed to install the package."
        exit 1
    fi
    if [[ "${perform_apt_update,,}" != "y" ]]; then
        linecolor "green" "Enabling apt update after adding repo."
        perform_apt_update="y"
        echo
    fi
}
function installnord {
    check_repo
    linebreak "Apt Update"
    if [[ "${perform_apt_update,,}" == "y" ]]; then
        if ! sudo apt update; then
            linecolor "red" "Apt update failed."
            exit 1
        fi
    else
        linecolor "red" "(Skipped)"
    fi
    if [[ "${install_gui,,}" == "y" ]]; then
        # when downgrading must install and specify a version for both packages, otherwise
        # nordvpn-gui will pull the latest version of the cli causing a version mismatch
        linebreak "Install $package_cli and $package_gui"
        if ! sudo apt install "$package_cli" "$package_gui" -y; then
            linecolor "red" "Installation failed."
            exit 1
        fi
    else
        # CLI only
        linebreak "Install $package_cli"
        if ! sudo apt install "$package_cli" -y; then
            linecolor "red" "Installation failed."
            exit 1
        fi
    fi
}
function start_service {
    linecolor "green" "Starting the service..."
    linecolor "cyan" "Trying: sudo systemctl start nordvpnd.service"
    echo
    if ! sudo systemctl start nordvpnd.service; then
        linecolor "red" "Failed to start nordvpnd.service"
        echo
        exit 1
    fi
    #
    local timeout="10"
    local count="0"
    local success="false"
    #
    echo -n "Waiting for service."
    while [[ "$count" -lt "$timeout" ]]
    do
        if systemctl is-active --quiet nordvpnd ||
           [[ -S /run/nordvpn/nordvpnd.sock ]]; then
            sleep 1
            if systemctl is-active --quiet nordvpnd ||
               [[ -S /run/nordvpn/nordvpnd.sock ]]; then
                success="true"
                break
            fi
        fi
        echo -n "."
        sleep 1
        ((count++))
    done
    echo
    #
    if [[ "$success" == "true" ]]; then
        linecolor "green" "nordvpnd.service has started."
        sleep 2
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
}
function check_group {
    linebreak "Check Group"
    if ! getent group nordvpn >/dev/null; then
        linecolor "purple" "'nordvpn' group doesn't exist."
        return
    fi
    if id -nG "$USER" | grep -qw "nordvpn"; then
        linecolor "green" "$USER belongs to the 'nordvpn' group."
        return
    fi
    linecolor "red" "$USER does not belong to the 'nordvpn' group."
    linecolor "cyan" "Trying: sudo usermod -aG nordvpn $USER"
    if sudo usermod -aG nordvpn "$USER"; then
        echo
        linecolor "purple" "$USER added to nordvpn group. Logout or Reboot to apply."
        linecolor "purple" "Run this script again after logging back in."
        echo
        exit 0
    else
        linecolor "red" "Failed to add user to group."
        exit 1
    fi
}
function loginnord {
    check_group
    linebreak "Check Service"
    if systemctl is-active --quiet nordvpnd; then
        linecolor "green" "nordvpnd.service is active"
    else
        start_service
    fi
    #
    linebreak "Disable Analytics"
    echo "Skip the user-consent prompt before login."
    echo "https://github.com/NordSecurity/nordvpn-linux/issues/958"
    echo "Refer to: https://my.nordaccount.com/legal/privacy-policy/"
    nordvpn set analytics disabled
    #
    if [[ -n "$login_token" ]]; then
        linebreak "Login (token)"
        nordvpn login --token "$login_token"
    else
        linebreak "Login (browser)"
        nordvpn login
        echo
        echo "Provide the Callback URL if necessary or"
        echo "just hit Enter after login is complete."
        echo
        read -r -p "Callback URL: " callback_url; echo
        echo
        if [[ -n "$callback_url" ]]; then
            linecolor "cyan" "nordvpn login --callback '$callback_url'"
            nordvpn login --callback "$callback_url"
            echo
        fi
    fi
    linebreak "Account"
    nordvpn account
}
function changelog {
    linebreak "Changelog"
    if [[ -f "$nord_changelog" ]]; then
        linecolor "green" "$nord_changelog"
        echo
        zcat -f "$nord_changelog" 2>/dev/null | head -n 15
    else
        linecolor "red" "$nord_changelog not found."
    fi
    echo
    linecolor "green" "https://nordvpn.com/blog/nordvpn-linux-release-notes/"
    linecolor "green" "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/"
}
function reload_applet {
    # reload the Nordlist Applet to change the icon color immediately
    if [[ -d "$HOME/.local/share/cinnamon/applets/nordlist_tray@ph202107" ]]; then
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
    PS3=$'\n'"Choose a Version (1-${#available_versions[@]}): "
    select choice in "${available_versions[@]}"
    do
        if (( 1 <= REPLY )) && (( REPLY <= ${#available_versions[@]} )); then
            app_version="${choice%% *}" # remove everything after the first space
            break
        else
            linecolor "red" "Invalid Option"
        fi
    done
}
function add_token {
    printascii "yellow" "TOKEN"
    if [[ -n "$login_token" ]]; then
        linecolor "red" "Token cleared."
        echo
    fi
    login_token=""
    token_expires=""
    read -r -p "Enter the login token: " login_token
    if [[ -z "$login_token" ]]; then
        linecolor "red" "(No Token)"
    fi
}
function check_status {
    cli_yes="$(linecolor "green" "CLI:")\u2705"     # unicode checkmark
    cli_no="$(linecolor "green" "CLI:")\u274c"      # unicode X
    gui_yes="$(linecolor "green" "GUI:")\u2705"
    gui_no="$(linecolor "green" "GUI:")\u274c"
    #
    command -v nordvpn &> /dev/null && cli_status="$cli_yes" || cli_status="$cli_no"
    command -v nordvpn-gui &> /dev/null && gui_status="$gui_yes" || gui_status="$gui_no"
    current_version=$( nordvpn --version 2>/dev/null || echo "Not Installed" )
    #
    command -v figlet &> /dev/null && figlet_exists="true" || figlet_exists="false"
    [[ "$gui_status" == "$gui_yes" ]] && install_gui="y" || install_gui="n"
}
function header {
    printascii "red" "NUCLEAR"
    echo -ne "$(linecolor "green" "Currently Installed: ")"
    echo -e "$current_version  $cli_status  $gui_status"
    echo
    #
    echo -ne "$(linecolor "green" "Version to Install: ")"
    if [[ "${app_version,,}" == "nordvpn" ]]; then
        echo -n "${app_version} (latest available)"
        package_cli="nordvpn"
        package_gui="nordvpn-gui"
    else
        echo -n "${app_version}"
        package_cli="nordvpn=${app_version}"
        package_gui="nordvpn-gui=${app_version}"
    fi
    echo -ne "  $cli_yes  "
    [[ "${install_gui,,}" == "y" ]] && echo -e "$gui_yes" || echo -e "$gui_no"
    echo
    #
    echo -ne "$(linecolor "yellow" "Login Token: ")"
    if [[ -n "$login_token" ]]; then
        echo "$login_token"
        if [[ -n "$token_expires" ]]; then
            echo
            echo -ne "$(linecolor "yellow" "Token Expires: ")"
            echo "$token_expires"
        fi
    else
        echo "No token. Log in with web browser."
    fi
    echo
    echo -ne "$(linecolor "purple" "Perform Apt Update:") "
    [[ "${perform_apt_update,,}" == "y" ]] && echo -e "\u2705" || echo -e "\u274c"
    echo
    echo -e "Type $(linecolor "green" "V") to choose another version."
    echo -e "Type $(linecolor "green" "G") to enable/disable GUI install."
    echo -e "Type $(linecolor "yellow" "T") to add/remove a token."
    echo -e "Type $(linecolor "purple" "A") to enable/disable 'apt update'."
    echo -e "Type $(linecolor "cyan" "E") to edit the script."
    echo
    read -n 1 -r -p "Go nuclear? (y/n/V/G/T/A/E) "; echo
    echo
}
#
# ========================================================================
#
if [[ "$EUID" -eq 0 ]]; then
    linecolor "red" "Script should be run by the interactive user, not root."
    linecolor "red" "Run './nuclear.sh' instead of 'sudo ./nuclear.sh'."
    echo
    exit 1
fi
#
titlebartext="NUCLEAR"
echo -ne "\033]2;${titlebartext}\007"
#
check_status
#
while true; do
    header
    case "${REPLY,,}" in
        v)
            choose_version
            ;;
        g)
            [[ "${install_gui,,}" != "y" ]] && install_gui="y" || install_gui="n"
            ;;
        t)
            add_token
            ;;
        a)
            [[ "${perform_apt_update,,}" != "y" ]] && perform_apt_update="y" || perform_apt_update="n"
            ;;
        e)
            edit_script
            exit
            ;;
        y)
            trashnord
            installnord
            loginnord
            changelog
            default_settings
            break
            ;;
        n)
            printascii "red" "ABORT"
            break
            ;;
        *)
            linecolor "red" "Invalid Option: $REPLY"
            ;;
    esac
done
#
linebreak "nordvpn settings"
nordvpn settings
linebreak "nordvpn status"
nordvpn status
linebreak "\n$(linecolor "green" "\U0001F3C1 Completed \U0001F3C1")"   # checkered flags
[[ "${REPLY,,}" != "n" ]] && check_status
echo -e "$current_version  $cli_status  $gui_status"
linebreak
reload_applet
#
# NordVPN CLI install:
#   sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh)
# NordVPN CLI + GUI install:
#   sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh) -p nordvpn-gui
#
