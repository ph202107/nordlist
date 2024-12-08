#!/bin/bash
#
# Tested with NordVPN Version 3.19.2 on Linux Mint 21.3
# December 8, 2024
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added a
# lot of comments to help fellow newbies customize the script.
#
# Screenshots:
# https://github.com/ph202107/nordlist/tree/main/screenshots
#
# https://github.com/ph202107/nordlist
# Suggestions/feedback welcome
#
# =====================================================================
# Instructions
# =============
#
# 1) Save as nordlist.sh
#       For convenience I use a directory in my PATH (echo $PATH)
#       eg. /home/username/.local/bin/nordlist.sh
# 2) Make the script executable with
#       "chmod +x nordlist.sh"
# 3) To generate ASCII images and to use NordVPN API functions
#       these small programs are required
#       eg. "sudo apt install figlet lolcat curl jq"
# 4) At the terminal run "nordlist.sh"
#       (Or "./nordlist.sh" from the directory if it's not in $PATH)
#
# =====================================================================
# Other Programs Used
# ====================
#
# wireguard-tools   Tools-WireGuard         (function wireguard_gen)
# speedtest-cli     Tools-Speed Tests       (function speedtest_menu)
# iperf3            Meshnet-Speed Tests     (function speedtest_iperf3)
# highlight         Settings-Script         (function script_info)
#
# "sudo apt install wireguard wireguard-tools speedtest-cli iperf3 highlight"
#
# For VPN On/Off status on the desktop I use the Linux Mint Cinnamon
# applet "Bash Sensors".  Highly recommended for Cinnamon DE users.
# Screenshot: https://github.com/ph202107/nordlist/blob/main/screenshots
# When the status icon is clicked, it will launch this script in a new
# terminal. The config is in the "Notes" at the bottom of the script.
#
# =====================================================================
# Sudo Usage
# ===========
#
#   These functions will ask for a sudo password:
#   - function restart_service
#   - function iptables_status
#   - function iptables_flush
#   - function wireguard_gen
#   - function customdns_menu "Flush DNS Cache"
#
# =====================================================================
# Customization
# ==============
#
# Specify your P2P preferred location.  (Optional)
# eg. p2pwhere="Canada" or p2pwhere="Toronto"
p2pwhere=""
#
# Specify your Obfuscated_Servers location. (Optional)
# The location must support obfuscation.
# eg. obwhere="United_States" or obwhere="Los_Angeles"
obwhere=""
#
# Specify the first hop to use for Double_VPN. (Optional)
# The location must have Double_VPN servers available.
# eg. dblwhere="United_Kingdom" or dblwhere="Sweden"
dblwhere=""
#
# Specify your Onion_Over_VPN location. (Optional)
# Typically Netherlands and Switzerland are available (~3 servers total)
# eg. torwhere="Netherlands" or torwhere="Switzerland"
torwhere=""
#
# Specify your Dedicated_IP location. (Optional)
# If you have a Dedicated IP you can specify your server, eg. "ca1692"
# Otherwise you can connect to the server group in a supported region.
# eg. dipwhere="Tokyo" or dipwhere="Johannesburg"
dipwhere=""
#
# Specify your Auto-Connect location. (Optional)
# eg. acwhere="Australia" or acwhere="Sydney"
# When obfuscate is enabled, the location must support obfuscation.
acwhere=""
#
# Specify your Custom-DNS servers with a description.
# Can specify up to 3 IP addresses separated by a space.
default_dns="103.86.96.100 103.86.99.100"; dnsdesc="Nord"
#
# Specify a VPN hostname to use for testing while the VPN is off.
# For example the VPN server configured on a local router.
# Can still enter any hostname later, this is just a default choice.
default_vpnhost="ca1576.nordvpn.com"
#
# Specify any hostname to lookup when testing DNS response time.
# Can also enter a different hostname later.
default_dnshost="reddit.com"
#
# Confirm the location of the NordVPN changelog on your system.
nordchangelog="/usr/share/doc/nordvpn/changelog.Debian.gz"
#
# Save incoming Meshnet file transfers into this folder.
# Note: $USER will automatically translate to your username.
# Use the absolute path, no trailing slash (/)
meshnetdir="/home/$USER/Downloads"
#
# Save generated WireGuard config files into this folder.
# Use the absolute path, no trailing slash (/)
wgdir="/home/$USER/Downloads"
#
# Specify the absolute path and filename to store a .json of all the
# NordVPN servers (about 20MB). Avoids API server timeouts.  Create the
# list at:  Tools - NordVPN API - All VPN Servers
nordserversfile="/home/$USER/Downloads/nord_allservers.json"
#
# Specify the absolute path and filename to store a local list of your
# favorite NordVPN servers.  eg. Low ping servers or streaming servers.
# Create the list in: 'Favorites'
nordfavoritesfile="/home/$USER/Downloads/nord_favorites.txt"
#
# Specify the absolute path and filename to save a copy of the
# nordvpnd.service logs.  Create the file in: Settings - Logs
nordlogfile="/home/$USER/Downloads/nord_logs.txt"
# Also show this number of lines from the tail of the log.
loglines="100"
#
# Change the terminal window titlebar text while the script is running.
# Leave this blank to keep the titlebar unchanged.
titlebartext="NORD"
#
# When changing servers disconnect the VPN first, then connect to the
# new server.  "y" or "n"
disconnect="n"
#
# Always 'Rate Server' when disconnecting via the main menu. "y" or "n"
rate_prompt="y"
#
# Ask to pause the VPN when disconnecting via the main menu
# (disconnect and automatically reconnect).  "y" or "n"
pause_prompt="y"
#
# Specify the default number of minutes to pause the VPN.
default_pause="5"
#
# Show the logo (ASCII and stats) when the script exits.  "y" or "n"
exitlogo="y"
#
# Always enable the Kill Switch (and Firewall) when the script exits
# and the VPN is connected.  "y" or "n"
exitkillswitch="n"
#
# Prompt to disable the Kill Switch when the script exits and
# the VPN is disconnected.  "y" or "n"
exitks_prompt="y"
#
# Ping the connected server when the script exits.  "y" or "n"
exitping="n"
#
# Query the current server load when the script exits.  "y" or "n"
# Requires 'curl' 'jq' and the local 'nordserversfile' mentioned above.
exitload="n"
#
# Show your external IP address when the script exits.  "y" or "n"
# Requires 'curl' and 'jq'.  Connects to ipinfo.io.
exitip="n"
#
# Reload the "Bash Sensors" Cinnamon applet when the script exits.
# This will change the icon color (for connection status) immediately.
# Only for the Cinnamon DE with "Bash Sensors" installed. "y" or "n"
exitappletb="n"
#
# Reload the "Network Manager" Cinnamon applet when the script exits.
# This removes duplicate "nordlynx" entries from the applet. "y" or "n"
exitappletn="n"
#
# Open http links in a new Firefox window.  "y" or "n"
# Choose "n" to use the default browser or method.
newfirefox="n"
#
# Specify the number of pings to send when pinging a destination.
pingcount="3"
#
# Set 'menuwidth' to your terminal width or lower.  This will compact
# the menus horizontally. ("Countries" and "Favorites" excluded.)
# Leave blank to have the menu width change with the window size.
menuwidth="80"
#
# Choose the maximum number of characters for country names in the
# "Countries" menu. Shortens long names so the menu fits better in the
# terminal window. Minimum is "6".  Leave blank to disable.
charlimit="12"
#
# Choosing 'Exit' in a submenu will take you to the main menu.
# Entering this value while in a submenu will return you to the default
# parent menu.  Also works with most (y/n) prompts to exit the prompt.
# To avoid conflicts avoid using any number other than zero, or
# the letters y,n,c,e,s.    eg. upmenu="0" or upmenu="b"
upmenu="0"
#
# =====================================================================
# Fast Options
# =============
#
# Fast options speed up the script by automatically answering 'yes'
# to prompts.  Would recommend trying the script to see how it operates
# before enabling these options.
#
# Choose "y" or "n"
#
# Return to the main menu without prompting "Press any key..."
fast1="n"
#
# Automatically change these settings without prompting:  Firewall,
# Routing, Analytics, KillSwitch, TPLite, Notify, Tray, AutoConnect,
# IPv6, LAN-Discovery, Virtual-Location, Post-Quantum
fast2="n"
#
# Automatically change these settings which also disconnect the VPN:
# Technology, Protocol, Obfuscate
fast3="n"
#
# Automatically disconnect, change settings, and connect to these
# groups: Obfuscated, Double-VPN, Onion+VPN, P2P, Dedicated-IP
fast4="n"
#
# Always enable the Kill Switch (& Firewall) when connecting to groups.
# (Does not apply when connecting through the "All_Groups" menu.)
fast5="n"
#
# Always choose the same protocol when asked to choose TCP or UDP.
# (Unless changing the setting through Settings - Protocol.)
fast6="n"       # "y" or "n"
fast6p="UDP"    # specify the protocol.  fast6p="UDP" or fast6p="TCP"
#
# When choosing a country from the 'Countries' menu, immediately
# connect to that country instead of choosing a city.
fast7="n"
#
# By default the 'F' indicator will be set when any of the 'fast'
# options are enabled.
# Modify 'allfast' if you want to display the 'F' indicator only when
# specific 'fast' options are enabled.
allfast=("$fast1" "$fast2" "$fast3" "$fast4" "$fast5" "$fast6" "$fast7")
#
# =====================================================================
# Virtual Servers
# ================
#
# Countries and Cities listed here will be labelled as (Virtual).
# Refer to: https://nordvpn.com/blog/new-nordvpn-virtual-servers/
# This list is subject to change and must be updated manually.
# Retrieve an updated list in "Tools - NordVPN API - All VPN Servers"
nordvirtual=(
"Accra" "Algeria" "Algiers" "Andorra" "Andorra_la_Vella" "Angola" "Argentina" "Armenia" "Astana" "Asuncion" "Azerbaijan" "Bahamas" "Baku" "Bandar_Seri_Begawan" "Bangkok" "Bangladesh" "Beirut" "Belize" "Belmopan" "Bermuda" "Bhutan" "Bolivia" "Brunei_Darussalam" "Buenos_Aires" "Cairo" "Cambodia" "Caracas" "Cayman_Islands" "Colombo" "Costa_Rica" "Dhaka" "Dominican_Republic" "Douglas" "Ecuador" "Egypt" "El_Salvador" "George_Town" "Ghana" "Greenland" "Guam" "Guatemala" "Guatemala_City" "Hagatna" "Hamilton" "Hanoi" "Ho_Chi_Minh_City" "Honduras" "India" "Isle_of_Man" "Jamaica" "Jersey" "Karachi" "Kathmandu" "Kazakhstan" "Kenya" "Kingston" "Lao_People's_Democratic_Republic" "La_Paz" "Lebanon" "Liechtenstein" "Luanda" "Malta" "Manila" "Maputo" "Monaco" "Mongolia" "Monte_Carlo" "Montenegro" "Montevideo" "Morocco" "Mozambique" "Mumbai" "Myanmar" "Nairobi" "Nassau" "Naypyidaw" "Nepal" "Nuuk" "Pakistan" "Panama" "Panama_City" "Papua_New_Guinea" "Paraguay" "Philippines" "Phnom_Penh" "Podgorica" "Port_Moresby" "Port_of_Spain" "Puerto_Rico" "Quito" "Rabat" "Saint_Helier" "San_Jose" "San_Juan" "San_Salvador" "Santo_Domingo" "Sri_Lanka" "Taipei" "Taiwan" "Tashkent" "Tegucigalpa" "Thailand" "Thimphu" "Trinidad_and_Tobago" "Ulaanbaatar" "Uruguay" "Uzbekistan" "Vaduz" "Valletta" "Venezuela" "Vientiane" "Vietnam" "Yerevan"
)
#
# =====================================================================
# Visual Options
# ===============
#
# Change the main menu figlet ASCII style in "function ascii_custom"
# Change the figlet ASCII style for headings in "function heading"
# Change the text and indicator colors in "function set_colors"
# Change the indicator layout in "function indicators_display"
#
# =====================================================================
# Allowlist & Default Settings
# =============================
#
# Add your allowlist commands to "function allowlist_commands"
# Set up a default NordVPN config in "function set_defaults"
#
# =====================================================================
# Main Menu
# ==========
#
# The Main Menu starts on line 400 (function main_menu).
# Configure the first ten main menu items to suit your needs.
#
# Enjoy!
#
# ==End================================================================
#
declare -A nordlist_apps    # populated in function app_exists
#
function allowlist_commands {
    # Add your allowlist configuration commands here.
    # Enter one command per line.
    # allowlist_start (keep this line as-is)
    #
    #nordvpn allowlist remove all
    #nordvpn allowlist add subnet 192.168.1.0/24
    #
    # allowlist_end (keep this line as-is)
    echo
}
function set_defaults {
    echo
    echo -e "${LColor}Apply the default configuration.${Color_Off}"
    echo
    # Calling this function can be useful to change multiple settings
    # at once and get back to a typical configuration.
    #
    # Configure as needed and comment-out the line below.
    echo -e "${WColor}** 'function set_defaults' not configured **${Color_Off}"; echo; return
    #
    # Notes:
    # - The VPN will be disconnected
    # - Kill Switch requires Firewall
    # - NordLynx is UDP only
    # - Obfuscate requires OpenVPN
    # - TPLite disables CustomDNS and vice versa
    # - LAN-Discovery will remove private subnets from Allowlist
    # - Post Quantum VPN requires NordLynx, and Meshnet disabled
    #
    # For each setting uncomment one of the two choices (or neither).
    #
    if [[ "$firewall" == "disabled" ]]; then nordvpn set firewall enabled; fi
    #if [[ "$firewall" == "enabled" ]]; then nordvpn set firewall disabled; fi
    #
    if [[ "$killswitch" == "disabled" ]]; then nordvpn set killswitch enabled; fi
    #if [[ "$killswitch" == "enabled" ]]; then nordvpn set killswitch disabled; fi
    #
    disconnect_vpn "force"
    #
    if [[ "$technology" == "openvpn" ]]; then if [[ "$protocol" == "TCP" ]]; then nordvpn set protocol UDP; fi; nordvpn set technology nordlynx; set_vars; fi
    #if [[ "$technology" == "nordlynx" ]]; then if [[ "$postquantum" == "enabled" ]]; then nordvpn set post-quantum disabled; fi; nordvpn set technology openvpn; set_vars; fi
    #
    if [[ "$protocol" == "TCP" ]]; then nordvpn set protocol UDP; fi
    #if [[ "$protocol" == "UDP" ]]; then nordvpn set protocol TCP; fi
    #
    if [[ "$routing" == "disabled" ]]; then nordvpn set routing enabled; fi
    #if [[ "$routing" == "enabled" ]]; then nordvpn set routing disabled; fi
    #
    #if [[ "$analytics" == "disabled" ]]; then nordvpn set analytics enabled; fi
    #if [[ "$analytics" == "enabled" ]]; then nordvpn set analytics disabled; fi
    #
    #if [[ "$tplite" == "disabled" ]]; then nordvpn set threatprotectionlite enabled; fi
    if [[ "$tplite" == "enabled" ]]; then nordvpn set threatprotectionlite disabled; fi
    #
    #if [[ "$obfuscate" == "disabled" ]]; then nordvpn set obfuscate enabled; fi
    if [[ "$obfuscate" == "enabled" ]]; then nordvpn set obfuscate disabled; fi
    #
    #if [[ "$notify" == "disabled" ]]; then nordvpn set notify enabled; fi
    if [[ "$notify" == "enabled" ]]; then nordvpn set notify disabled; fi
    #
    #if [[ "$tray" == "disabled" ]]; then nordvpn set tray enabled; fi
    #if [[ "$tray" == "enabled" ]]; then nordvpn set tray disabled; fi
    #
    #if [[ "$autoconnect" == "disabled" ]]; then nordvpn set autoconnect enabled $acwhere; fi
    if [[ "$autoconnect" == "enabled" ]]; then nordvpn set autoconnect disabled; fi
    #
    #if [[ "$ipversion6" == "disabled" ]]; then nordvpn set ipv6 enabled; fi
    if [[ "$ipversion6" == "enabled" ]]; then nordvpn set ipv6 disabled; fi
    #
    #if [[ "$meshnet" == "disabled" ]]; then nordvpn set meshnet enabled; fi
    #if [[ "$meshnet" == "enabled" ]]; then nordvpn set meshnet disabled; fi
    #
    #if [[ "$customdns" == "disabled" ]]; then nordvpn set dns $default_dns; fi
    #if [[ "$customdns" != "disabled" ]]; then nordvpn set dns disabled; fi
    #
    #if [[ "$landiscovery" == "disabled" ]]; then nordvpn set lan-discovery enabled; fi
    #if [[ "$landiscovery" == "enabled" ]]; then nordvpn set lan-discovery disabled; fi
    #
    #if [[ "$virtual" == "disabled" ]]; then nordvpn set virtual-location enabled; fi
    #if [[ "$virtual" == "enabled" ]]; then nordvpn set virtual-location disabled; fi
    #
    #if [[ "$postquantum" == "disabled" ]]; then nordvpn set post-quantum enabled; fi
    #if [[ "$postquantum" == "enabled" ]]; then nordvpn set post-quantum disabled; fi
    #
    echo
}
function main_menu {
    if [[ "$1" == "start" ]]; then
        echo -e "${EIColor}Welcome to nordlist!${Color_Off}"
    elif [[ "$fast1" =~ ^[Yy]$ ]] || [[ "$REPLY" == "$upmenu" ]]; then
        echo
    else
        echo; echo
        read -n 1 -s -r -p "Press any key for the menu... "; echo
    fi
    echo
    #
    clear -x
    main_logo
    parent="Main"
    COLUMNS="$menuwidth"
    PS3=$'\n''Choose an option: '
    #
    # =================================================================
    # ====== MAIN MENU ================================================
    # =================================================================
    #
    # To modify the menu, for example changing Vancouver to Melbourne:
    #  - In the (Menu Array) below
    #       replace "Vancouver" with "Melbourne"
    #  - In the (Case Statement) below
    #       also replace "Vancouver" with "Melbourne"
    #       and replace: "nordvpn connect Vancouver"
    #       with:        "nordvpn connect Melbourne"
    # No other changes are necessary.
    #
    # Each option in the Menu Array should have a matching case.
    # Spelling and capitalization must match exactly in both places.
    #
    # An almost unlimited number of menu items can be added.
    # Submenu functions can be added to the main menu for easier access.
    #
    # =====  (Menu Array)  =====
    # These are the options that will be displayed on the main menu.
    mainmenu=( "Vancouver" "Seattle" "Chicago" "Denver" "Atlanta" "US_Cities" "CA_Cities" "P2P-USA" "P2P-Canada" "Discord" "QuickConnect" "Random" "Favorites" "Countries" "Groups" "Settings" "Tools" "Meshnet" "Disconnect" "Exit" )
    #
    select opt in "${mainmenu[@]}"
    do
        parent_menu
        case $opt in
        #
        # =====  (Case Statement)  =====
        # These are the commands that run when a menu option is selected.
        #
            "Vancouver")
                main_header
                nordvpn connect Vancouver
                status
                break
                ;;
            "Seattle")
                main_header
                nordvpn connect Seattle
                status
                break
                ;;
            "Chicago")
                main_header
                nordvpn connect Chicago
                status
                break
                ;;
            "Denver")
                main_header
                nordvpn connect Denver
                status
                break
                ;;
            "Atlanta")
                main_header
                nordvpn connect Atlanta
                status
                break
                ;;
            "US_Cities")
                # city menu for United_States
                xcountry="United_States"
                city_menu "Main"
                ;;
            "CA_Cities")
                # city menu for Canada
                xcountry="Canada"
                city_menu "Main"
                ;;
            "P2P-USA")
                # force a disconnect and apply default settings
                main_header "defaults"
                nordvpn connect --group p2p United_States
                status
                break
                ;;
            "P2P-Canada")
                # force a disconnect and apply default settings
                main_header "defaults"
                nordvpn connect --group p2p Canada
                status
                break
                ;;
            "Discord")
                # I use this entry to connect to a specific server which can help
                # avoid repeat authentication requests. It then opens a URL.
                # It may be useful for other sites or applications.
                # Example: NordVPN discord  https://discord.gg/83jsvGqpGk
                #
                spec_server="us8247"
                spec_url="https://discord.gg/83jsvGqpGk"
                #
                main_header
                echo -e "Server: ${LColor}$spec_server${Color_Off}"
                echo -e "URL: ${EColor}$spec_url${Color_Off}"
                echo
                nordvpn connect "$spec_server"
                status
                openlink "$spec_url"
                break
                ;;
            "Hostname")
                # can add to mainmenu
                # connect to specific servers by name
                host_connect
                ;;
            "QuickConnect")
                # alternative to "nordvpn connect"
                quick_connect
                ;;
            "Random")
                # connect to a random city worldwide
                random_worldwide
                ;;
            "Favorites")
                # connect from a list of individual server names
                favorites_menu
                ;;
            "Countries")
                country_menu
                ;;
            "Groups")
                group_menu
                ;;
            "Settings")
                settings_menu
                ;;
            "Tools")
                tools_menu
                ;;
            "Meshnet")
                meshnet_menu
                ;;
            "Disconnect")
                main_disconnect
                ;;
            "Exit")
                heading "Goodbye!"
                status
                break
                ;;
            *)
                invalid_option "${#mainmenu[@]}" "TopMenu"
                main_menu
                ;;
        esac
    done
    exit
}
function ascii_static {
    # This ASCII will display above the main menu if figlet or lolcat is not installed.
    # You can also use your own ASCII art and specify "ascii_static" in "function main_logo".
    # Change the color in "function set_colors".
    echo -ne "${ASColor}"
    #
cat << "EOF"
 _   _               ___     ______  _   _
| \ | | ___  _ __ __| \ \   / /  _ \| \ | |
|  \| |/ _ \| '__/ _' |\ \ / /| |_) |  \| |
| |\  | (_) | | | (_| | \ V / |  __/| |\  |
|_| \_|\___/|_|  \__,_|  \_/  |_|   |_| \_|

EOF
    #
    echo -ne "${Color_Off}"
}
function ascii_custom {
    if ! app_exists "figlet" || ! app_exists "lolcat"; then
        ascii_static
        return
    fi
    # This ASCII is displayed above the main menu.  Any text or variable(s) can be used.
    # eg. "$city", "$country", "$transferd", "NordVPN", "$HOSTNAME", "$(date)", etc.
    #
    asciitext="$city"
    #
    if "$meshrouting"; then
        # when routing through meshnet
        asciitext="Meshnet Routing"
    fi
    if [[ "$connected" == "connected" ]]; then
        # Add or remove any figlet fonts, arrange from largest to smallest or by preference.
        for figletfont in slant standard smslant small none
        do
            if [[ "$figletfont" == "none" ]]; then
                # If no ascii fonts will fit then print regular text.
                echo
                echo "======  ${asciitext^^}  ======" | lolcat -p 0.7
                #echo -e "${H1Color}======  ${asciitext^^}  ======${Color_Off}"
                echo
            elif (( "$(tput cols)" > "$(wc -L <<< "$(figlet -w 999 -f "$figletfont" "$asciitext")")" )); then
                # Check the current terminal width, and the width required for the ascii font.
                figlet -t -f "$figletfont" "$asciitext" | lolcat
                break
            fi
        done
    else
        # style when disconnected
        figlet -t -f "standard" "NordVPN"
    fi
}
function indicators_display {
    # The "nordvpn settings" enabled/disabled indicators shown on the main menu, settings menu, and group connect.
    # $1 = "group" - group menu indicators
    #
    # Use any symbol to separate the indicators.  Set a color in function set_colors.
    #indsep=" "         # blank space
    #indsep="\u2758"    # unicode vertical line
    indsep="\u00B7"     # unicode middle-dot
    #
    if [[ "$1" == "group" ]]; then
        echo -n "Current settings: "
        indall=( "$techpro" "$fw" "$ks" "$ob" "$pq" )
    else
        indall=( "$techpro" "$fw" "$rt" "$an" "$ks" "$tp" "$ob" "$no" "$tr" "$ac" "$ip6" "$mn" "$dns" "$ld" "$vl" "$pq" "$al" )
        if [[ -n "$fst" ]]; then indall+=( "$fst" ); fi
        if [[ -n "$sshi" ]]; then indall+=( "$sshi" ); fi
    fi
    # array index (starts at zero)
    for idx in "${!indall[@]}"; do
        echo -ne "${indall[idx]}"
        if (( (idx + 1) < "${#indall[@]}" )); then
            echo -ne "${ISColor}$indsep${Color_Off}"
        fi
    done
    echo
}
function main_logo {
    # The ascii and stats shown above the main_menu and on script exit.
    set_vars
    if [[ "$1" != "stats_only" ]]; then
        # Specify  ascii_static or ascii_custom on the line below.
        ascii_custom
    fi
    if "$meshrouting"; then
        echo -e "$connectedcl ${SVColor}$nordhost ${IPColor}$ipaddr${Color_Off}"
    else
        echo -e "$connectedcl ${CIColor}$city ${COColor}$country ${SVColor}$server ${IPColor}$ipaddr ${Color_Off}$fav"
    fi
    indicators_display
    echo -e "$transferc ${UPColor}$uptime${Color_Off}"
    if [[ -n "$transferc" ]]; then echo; fi
}
function heading {
    # The text or ASCII that displays after a menu selection is made.
    # $1 = heading text
    # $2 = "txt" - use regular text instead of figlet
    # $3 = "alt" - use alternate color for regular text
    #
    clear -x
    if ! app_exists "figlet" || ! app_exists "lolcat" || [[ "$2" == "txt" ]]; then
        echo
        if [[ "$3" == "alt" ]]; then
            echo -e "${H2Color}=== $1 ===${Color_Off}"
        else
            echo -e "${H1Color}=== $1 ===${Color_Off}"
        fi
        echo
    else
        # Add or remove any figlet fonts, arrange from largest to smallest or by preference.
        for figletfont in slant standard smslant small none
        do
            if [[ "$figletfont" == "none" ]]; then
                # If no ascii fonts will fit then print regular text.
                echo
                echo -e "${H1Color}=== $1 ===${Color_Off}"
                echo
            elif (( "$(tput cols)" > "$(wc -L <<< "$(figlet -w 999 -f "$figletfont" "$1")")" )); then
                # Check the current terminal width, and the width required for the ascii font.
                figlet -t -f "$figletfont" "$1" | lolcat -p 1000
                break
            fi
        done
    fi
    if [[ "$1" == "Countries" ]] || [[ "$1" == "Favorites" ]]; then
        return
    else
        COLUMNS="$menuwidth"
    fi
}
function set_colors {
    #
    # shellcheck disable=SC2034
    # supress warning about unused color variables
    {
        # Regular
        Black='\033[0;30m'
        Red='\033[0;31m'
        Green='\033[0;32m'
        Yellow='\033[0;33m'
        Blue='\033[0;34m'
        Purple='\033[0;35m'
        Cyan='\033[0;36m'
        White='\033[0;97m'
        #
        # Light
        LGrey='\033[0;37m'
        DGrey='\033[0;90m'  # Dark
        LRed='\033[0;91m'
        LGreen='\033[0;92m'
        LYellow='\033[0;93m'
        LBlue='\033[0;94m'
        LPurple='\033[0;95m'
        LCyan='\033[0;96m'
        #
        # Bold
        BBlack='\033[1;30m'
        BRed='\033[1;31m'
        BGreen='\033[1;32m'
        BYellow='\033[1;33m'
        BBlue='\033[1;34m'
        BPurple='\033[1;35m'
        BCyan='\033[1;36m'
        BWhite='\033[1;37m'
        #
        # Underline
        UBlack='\033[4;30m'
        URed='\033[4;31m'
        UGreen='\033[4;32m'
        UYellow='\033[4;33m'
        UBlue='\033[4;34m'
        UPurple='\033[4;35m'
        UCyan='\033[4;36m'
        UWhite='\033[4;37m'
        #
        # Background
        # eg: ${White}${On_Red} = White text on red background
        On_Black='\033[40m'
        On_Red='\033[41m'
        On_Green='\033[42m'
        On_Yellow='\033[43m'
        On_Blue='\033[44m'
        On_Purple='\033[45m'
        On_Cyan='\033[46m'
        On_White='\033[47m'
        #
        Color_Off='\033[0m'
    }
    #
    # ============== Change colors here if needed. ====================
    #
    EColor=${LGreen}        # Enabled text
    EIColor=${BGreen}       # Enabled indicator
    DColor=${LRed}          # Disabled text
    DIColor=${BRed}         # Disabled indicator
    FColor=${LYellow}       # Fast text
    FIColor=${BYellow}      # Fast indicator
    TColor=${BPurple}       # Technology and Protocol text
    TIColor=${BPurple}      # Technology and Protocol indicator
    #
    WColor=${BRed}          # Warnings, errors, disconnects
    LColor=${LCyan}         # 'Changes' lists and key info text
    ASColor=${BBlue}        # Color for the ascii_static image
    H1Color=${LGreen}       # Non-figlet headings
    H2Color=${LCyan}        # Non-figlet headings alternate
    # main_logo
    CNColor=${LGreen}       # Connected status
    DNColor=${LRed}         # Disconnected status
    CIColor=${Color_Off}    # City name
    COColor=${Color_Off}    # Country name
    SVColor=${Color_Off}    # Server name
    IPColor=${Color_Off}    # IP address
    FVColor=${LCyan}        # Favorite|Dedicated-IP|Virtual label
    ISColor=${DGrey}        # Indicators separator
    DLColor=${Green}        # Download stat
    ULColor=${Yellow}       # Upload stat
    UPColor=${Cyan}         # Uptime stat
    #
}
#
# =====================================================================
# =====================================================================
#
function nstatus_search {
    # search the nstatus array by line
    # $1 = search string
    # $2 = "line" - return the entire line
    #
    if [[ "$2" == "line" ]]; then
        printf '%s\n' "${nstatus[@]}" | grep -i "$1"
    else
        # the last field using <colon><space> as delimiter
        # some elements may have spaces eg Los Angeles, United States
        printf '%s\n' "${nstatus[@]}" | grep -i "$1" | awk -F': ' '{print $NF}'
    fi
}
function nsettings_search {
    # search the nsettings array by line
    # $1 = search string
    # $2 = "line" - return the entire line
    #
    if [[ "$2" == "line" ]]; then
        printf '%s\n' "${nsettings[@]}" | grep -i "$1"
    else
        # the last field using <space> as delimiter
        printf '%s\n' "${nsettings[@]}" | grep -i "$1" | awk -F' ' '{print $NF}'
    fi
}
function set_vars {
    # Store info in arrays (BASH v4)
    readarray -t nstatus < <( nordvpn status | tr -d '\r' )
    readarray -t nsettings < <( nordvpn settings | tr -d '\r' | tr '[:upper:]' '[:lower:]' )
    #
    # "nordvpn status"
    # When disconnected, $connected is the only variable from nstatus
    # When meshnet is enabled, the transfer stats will not be zeroed on VPN reconnect.
    connected=$( nstatus_search "Status" | tr '[:upper:]' '[:lower:]' )
    servername=$( nstatus_search "Server" )
    nordhost=$( nstatus_search "Hostname" )
    server=$( echo "$nordhost" | cut -f1 -d'.' )
    ipaddr=$( nstatus_search "IP:" )
    country=$( nstatus_search "Country" )
    city=$( nstatus_search "City" )
    protocol2=$( nstatus_search "protocol" | tr '[:lower:]' '[:upper:]' )
    transferd=$( nstatus_search "Transfer" "line" | cut -f 2-3 -d' ' )  # download stat with units
    transferu=$( nstatus_search "Transfer" "line" | cut -f 5-6 -d' ' )  # upload stat with units
    uptime=$( nstatus_search "Uptime" "line" | cut -f 1-9 -d' ' )
    #
    # "nordvpn settings"
    # $protocol and $obfuscate are not listed when using NordLynx
    # $postquantum is not listed when using OpenVPN
    technology=$( nsettings_search "Technology" )
    protocol=$( nsettings_search "Protocol" | tr '[:lower:]' '[:upper:]' )
    firewall=$( nsettings_search "Firewall:" )
    fwmark=$( nsettings_search "Firewall Mark" )
    routing=$( nsettings_search "Routing" )
    analytics=$( nsettings_search "Analytics" )
    killswitch=$( nsettings_search "Kill" )
    tplite=$( nsettings_search "Threat" )
    obfuscate=$( nsettings_search "Obfuscate" )
    notify=$( nsettings_search "Notify" )
    tray=$( nsettings_search "Tray" )
    autoconnect=$( nsettings_search "Auto" )
    ipversion6=$( nsettings_search "IPv6" )
    meshnet=$( nsettings_search "Meshnet" | tr -d '\n' )
    customdns=$( nsettings_search "DNS" )                                       # disabled or not=disabled
    dns_servers=$( nsettings_search "DNS" "line" | tr '[:lower:]' '[:upper:]' ) # Server IPs, includes "DNS: "
    landiscovery=$( nsettings_search "Discover" )
    virtual=$( nsettings_search "Virtual" )
    postquantum=$( nsettings_search "quantum" )
    allowlist=$( printf '%s\n' "${nsettings[@]}" | grep -A100 -i "allowlist" )
    #
    # Prefer common spelling.
    if [[ "$technology" == "openvpn" ]]; then technologyd="OpenVPN"
    elif [[ "$technology" == "nordlynx" ]]; then technologyd="NordLynx"
    fi
    technologydc="${TColor}$technologyd${Color_Off}"
    #
    # To display the protocol for either Technology whether connected or disconnected.
    if [[ "$connected" == "connected" ]]; then protocold="$protocol2"
    elif [[ "$technology" == "nordlynx" ]]; then protocold="UDP"
    else protocold="$protocol"
    fi
    protocoldc="${TColor}$protocold${Color_Off}"
    #
    techpro="${TIColor}$technologyd\u00B7$protocold${Color_Off}"
    #
    if [[ "$connected" == "connected" ]]; then
        connectedc="${CNColor}$connected${Color_Off}"
        connectedcl="${CNColor}${connected^}${Color_Off}:"
        transferc="${DLColor}\u25bc $transferd ${ULColor} \u25b2 $transferu ${Color_Off}"
    else
        connectedc="${DNColor}$connected${Color_Off}"
        connectedcl="${DNColor}${connected^}${Color_Off}"
        transferc=""
    fi
    #
    if [[ "$firewall" == "enabled" ]]; then
        fw="${EIColor}FW${Color_Off}"
        firewallc="${EColor}$firewall${Color_Off}"
    else
        fw="${DIColor}FW${Color_Off}"
        firewallc="${DColor}$firewall${Color_Off}"
    fi
    #
    if [[ "$routing" == "enabled" ]]; then
        rt="${EIColor}RT${Color_Off}"
        routingc="${EColor}$routing${Color_Off}"
    else
        rt="${DIColor}RT${Color_Off}"
        routingc="${DColor}$routing${Color_Off}"
    fi
    #
    if [[ "$analytics" == "enabled" ]]; then
        an="${EIColor}AN${Color_Off}"
    else
        an="${DIColor}AN${Color_Off}"
    fi
    #
    if [[ "$killswitch" == "enabled" ]]; then
        ks="${EIColor}KS${Color_Off}"
        killswitchc="${EColor}$killswitch${Color_Off}"
    else
        ks="${DIColor}KS${Color_Off}"
        killswitchc="${DColor}$killswitch${Color_Off}"
    fi
    #
    if [[ "$tplite" == "enabled" ]]; then
        tp="${EIColor}TP${Color_Off}"
    else
        tp="${DIColor}TP${Color_Off}"
    fi
    #
    if [[ "$obfuscate" == "enabled" ]]; then
        ob="${EIColor}OB${Color_Off}"
        obfuscatec="${EColor}$obfuscate${Color_Off}"
    else
        ob="${DIColor}OB${Color_Off}"
        obfuscatec="${DColor}$obfuscate${Color_Off}"
    fi
    #
    if [[ "$notify" == "enabled" ]]; then
        no="${EIColor}NO${Color_Off}"
    else
        no="${DIColor}NO${Color_Off}"
    fi
    #
    if [[ "$tray" == "enabled" ]]; then
        tr="${EIColor}TR${Color_Off}"
    else
        tr="${DIColor}TR${Color_Off}"
    fi
    #
    if [[ "$autoconnect" == "enabled" ]]; then
        ac="${EIColor}AC${Color_Off}"
    else
        ac="${DIColor}AC${Color_Off}"
    fi
    #
    if [[ "$ipversion6" == "enabled" ]]; then
        ip6="${EIColor}IP6${Color_Off}"
    else
        ip6="${DIColor}IP6${Color_Off}"
    fi
    #
    if [[ "$meshnet" == "enabled" ]]; then
        mn="${EIColor}MN${Color_Off}"
        meshnetc="${EColor}$meshnet${Color_Off}"
    else
        mn="${DIColor}MN${Color_Off}"
        meshnetc="${DColor}$meshnet${Color_Off}"
    fi
    #
    if [[ "$customdns" == "disabled" ]]; then # reversed
        dns="${DIColor}DNS${Color_Off}"
    else
        dns="${EIColor}DNS${Color_Off}"
    fi
    #
    if [[ "$landiscovery" == "enabled" ]]; then
        ld="${EIColor}LD${Color_Off}"
        landiscoveryc="${EColor}$landiscovery${Color_Off}"
    else
        ld="${DIColor}LD${Color_Off}"
        landiscoveryc="${DColor}$landiscovery${Color_Off}"
    fi
    #
    if [[ "$virtual" == "enabled" ]]; then
        vl="${EIColor}VL${Color_Off}"
        virtualc="${EColor}$virtual${Color_Off}"
    else
        vl="${DIColor}VL${Color_Off}"
        virtualc="${DColor}$virtual${Color_Off}"
    fi
    #
    if [[ "$postquantum" == "enabled" ]]; then
        pq="${EIColor}PQ${Color_Off}"
        postquantumc="${EColor}$postquantum${Color_Off}"
    else
        pq="${DIColor}PQ${Color_Off}"
        # $postquantum not listed when using openvpn
        postquantumc="${DColor}disabled${Color_Off}"
    fi
    #
    if [[ -n "${allowlist[*]}" ]]; then # not empty
        al="${EIColor}AL${Color_Off}"
    else
        al="${DIColor}AL${Color_Off}"
    fi
    #
    if [[ ${allfast[*]} =~ [Yy] ]]; then
        fst="${FIColor}F${Color_Off}"
    else
        fst=""
    fi
    #
    if "$usingssh"; then
        sshi="${FIColor}SSH${Color_Off}"
    else
        sshi=""
    fi
    #
    if [[ "$connected" == "connected" ]] && [[ "$meshnet" == "enabled" ]] && [[ "$nordhost" != *"nordvpn.com"* ]]; then
        meshrouting="true"
    else
        meshrouting="false"
    fi
    #
    if [[ "$connected" == "connected" ]] && [[ "$technology" == "openvpn" ]] && [[ "${server,,}" == "${dipwhere,,}" ]]; then
        fav="${FVColor}(Dedicated-IP)${Color_Off}"
    elif [[ "$connected" == "connected" ]] && [[ -f "$nordfavoritesfile" ]] && grep -q -i "$server" "$nordfavoritesfile"; then
        fav="${FVColor}(Favorite)${Color_Off}"
    elif [[ "$connected" == "connected" ]] && [[ "${servername,,}" == *"virtual"* ]]; then
        fav="${FVColor}(Virtual)${Color_Off}"
    else
        fav=""
    fi
}
function disconnect_vpn {
    # $1 = "force" - force a disconnect
    # $2 = "check_ks" - prompt to disable the killswitch
    #
    echo
    if [[ "$disconnect" =~ ^[Yy]$ ]] || [[ "$1" == "force" ]]; then
        set_vars
        if [[ "$connected" == "connected" ]]; then
            if [[ "$2" == "check_ks" ]] && [[ "$killswitch" == "enabled" ]]; then
                echo -e "${WColor}** Reminder **${Color_Off}"
                change_setting "killswitch" "back"
            fi
            echo -e "${WColor}** Disconnect **${Color_Off}"
            echo
            nordvpn disconnect; wait
            echo
        fi
    fi
}
function ipinfo_curl {
    echo -n "External IP: "
    response=$( timeout 6 curl --silent "https://ipinfo.io/" )
    #
    extip=$(echo "$response" | jq -r '.ip | if . == null then empty else . end')
    exthost=$(echo "$response" | jq -r '.hostname | if . == null then empty else . end')
    extorg=$(echo "$response" | jq -r '.org | if . == null then empty else . end')
    extcity=$(echo "$response" | jq -r '.city | if . == null then empty else . end')
    extregion=$(echo "$response" | jq -r '.region | if . == null then empty else . end')
    extcountry=$(echo "$response" | jq -r '.country | if . == null then empty else . end')
    extlimit=$(echo "$response" | jq -r '.error.title | if . == null then empty else . end')
    #
    if [[ -n "$extip" ]]; then
        echo -e "${IPColor}$extip  $exthost${Color_Off}"
        echo -e "${SVColor}$extorg ${CIColor}$extcity $extregion ${COColor}$extcountry${Color_Off}"
        echo
    elif [[ -n "$extlimit" ]]; then
        echo -e "${WColor}$extlimit${Color_Off}"
        echo
    else
        set_vars
        echo -n "Request failed"
        if [[ "$connected" != "connected" ]] && [[ "$killswitch" == "enabled" ]]; then
            echo -ne " - $ks"
        fi
        echo; echo
    fi
}
function status {
    reload_applet
    echo
    nordvpn settings
    echo
    nordvpn status
    echo
    if [[ "$exitlogo" =~ ^[Yy]$ ]]; then
        clear -x
        main_logo
    else
        set_vars
    fi
    if [[ "$connected" == "connected" ]]; then
        if [[ "$exitkillswitch" =~ ^[Yy]$ ]] && [[ "$killswitch" == "disabled" ]]; then
            echo -e "${FColor}(exitkillswitch) - Always enable the Kill Switch.${Color_Off}"
            killswitch_enable
            if [[ "$exitlogo" =~ ^[Yy]$ ]]; then
                echo -e "${FColor}Updating the logo.${Color_Off}"
                clear -x
                main_logo
            fi
        fi
        if [[ "$exitping" =~ ^[Yy]$ ]]; then
            if [[ "$technology" == "openvpn" ]]; then
                echo -ne "$technologydc - Ping the External IP"
                if [[ ! "$exitip" =~ ^[Yy]$ ]]; then
                    echo -ne " (Set ${FColor}exitip=\"y\"${Color_Off} to enable)"
                fi
                echo
            else
                ping_host "$ipaddr" "stats" "$nordhost"
            fi
            echo
        fi
        if [[ "$exitload" =~ ^[Yy]$ ]]; then
            server_load
        fi
    else
        # VPN disconnected
        if [[ "$exitks_prompt" =~ ^[Yy]$ ]] && [[ "$killswitch" == "enabled" ]]; then
            echo -e "${WColor}** Reminder **${Color_Off}"
            change_setting "killswitch" "back"
        fi
    fi
    if [[ "$exitip" =~ ^[Yy]$ ]]; then
        ipinfo_curl
        if [[ "$connected" == "connected" ]] && [[ "$exitping" =~ ^[Yy]$ ]] && [[ -n "$extip" ]]; then
            if [[ "$technology" == "openvpn" ]] || "$meshrouting"; then
                # ping the external IP when using OpenVPN or Meshnet Routing
                ping_host "$extip" "stats" "External IP"
                echo
            elif [[ "$server" == *"-"* ]] && [[ "$server" != *"onion"* ]] && [[ "$server" != *"napps"* ]]; then
                # ping both hops of Double-VPN servers when using NordLynx
                ping_host "$extip" "stats" "Double-VPN"
                echo
            fi
        fi
    fi
    date
    echo
}
function reload_applet {
    # reload Cinnamon Desktop applets
    #
    if "$usingssh"; then return; fi
    if [[ "$exitappletb" =~ ^[Yy]$ ]]; then
        # reload 'bash-sensors@pkkk' - changes the icon color (for connection status) immediately.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'bash-sensors@pkkk' string:'APPLET'
        wait
    fi
    if [[ "$exitappletn" =~ ^[Yy]$ ]]; then
        # reload 'network@cinnamon.org' - removes extra 'nordlynx' entries.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'network@cinnamon.org' string:'APPLET'
        wait
    fi
}
function ping_host {
    # $1 = destination
    # $2 = "stats" - display the stats only, with a label
    # $2 = "show" - display the ping command first
    # $3 = the label used with "stats"
    #
    if [[ "$2" == "stats" ]]; then
        echo -ne "${LColor}($3) ${Color_Off}"
        ping -c "$pingcount" -q "$1" | grep -A4 -i "statistics"
    elif [[ "$2" == "show" ]]; then
        echo -e "${LColor}ping -c $pingcount $1${Color_Off}"
        echo
        ping -c "$pingcount" "$1"
        echo
    else
        ping -c "$pingcount" "$1"
    fi
}
function disconnect_warning {
    set_vars
    if [[ "$connected" == "connected" ]]; then
        echo -e "${WColor}** Changing this setting will disconnect the VPN **${Color_Off}"
        echo
    fi
}
function openlink {
    # $1 = URL or link to open
    # $2 = "ask"  - ask first
    # $3 = "exit" - exit after opening
    #
    if "$usingssh"; then
        echo
        echo -e "${FColor}The script is running over SSH${Color_Off}"
        echo
    fi
    if [[ "$2" == "ask" ]] || "$usingssh"; then
        read -n 1 -r -p "$(echo -e "Open ${EColor}$1${Color_Off} ? (y/n) ")"; echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    if [[ "$1" =~ ^https?:// ]] && [[ "$newfirefox" =~ ^[Yy]$ ]] && ! "$usingssh"; then
        # open urls in a new firefox window if the option is enabled
        nohup "$(command -v firefox)" --new-window "$1" > /dev/null 2>&1 &
    elif [[ "$1" == *.conf || "$1" == *.sh || "$1" == *.txt ]] && "$usingssh"; then
        # open these types of files in the terminal when using ssh
        # WireGuard configs, nordlist.sh, favorites.txt, nord_logs.txt
        # check for default editor otherwise use nano
        if [[ -n "$VISUAL" ]]; then
            editor="$VISUAL"
        elif [[ -n "$EDITOR" ]]; then
            editor="$EDITOR"
        else
            editor="nano"
        fi
        "$editor" "$1"
    else
        # use system default method
        nohup xdg-open "$1" > /dev/null 2>&1 &
    fi
    if [[ "$3" == "exit" ]]; then
        echo
        exit
    fi
    # https://github.com/suan/local-open
}
function countdown_timer {
    # Adds about 15s per hour but close enough.
    # $1 = time in seconds
    #
    echo -e "Type ${LColor}R${Color_Off} to quit the timer and resume."
    echo
    echo "Countdown:"
    for ((i="$1"; i>=0; i--))
    do
        days=$(( "$i" / 86400 ))
        if (( days >= 1 )); then
            echo -ne "    $days days and $(date -u -d "@$i" +%H:%M:%S)\033[0K\r"
        else
            echo -ne "    $(date -u -d "@$i" +%H:%M:%S)\033[0K\r"
        fi
        read -t 1 -n 1 -r -s countinput
        if [[ "$countinput" =~ ^[Rr]$ ]]; then
            echo -e "    ${WColor}Quit${Color_Off}\033[0K\r"
            break
        fi
    done
    echo
}
function parent_menu {
    # $1 = $1 or $2 (back) of the calling function - disable upmenu if a return is required
    #
    if [[ "$REPLY" == "$upmenu" ]]; then
        if [[ "$1" == "back" ]]; then
            echo
            echo -e "${FColor}(upmenu) - N/A - The function needs to return.${Color_Off}"
            echo
        else
            echo
            echo -e "${FColor}(upmenu) - Return to the $parent menu.${Color_Off}"
            case "$parent" in
                "Main")         main_menu;;
                "Country")      country_menu;;
                "Settings")     settings_menu;;
                "Group")        group_menu;;
                "Tools")        tools_menu;;
                "Nord API")     nordapi_menu;;
                "Meshnet")      meshnet_menu;;
                "Favorites")    favorites_menu;;
                "All Servers")  allservers_menu;;
                "Speed Test")   speedtest_menu;;
            esac
        fi
    fi
}
function invalid_option {
    # $1 = total menu items
    # $2 = $parent - name of parent menu
    #
    echo
    echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
    echo
    echo "Select any number from 1-$1, or enter $upmenu"
    if [[ "$2" == "TopMenu" ]]; then
        echo " $upmenu = Reload the Main menu"
        echo " $1 = Exit the script"
    elif [[ "$2" == "Main" ]]; then
        echo " $upmenu or $1 = Return to the Main menu"
    else
        echo " $upmenu = Return to the $2 menu"
        echo " $1 = Exit to the Main menu"
    fi
}
function create_list {
    #
    # remove notices by keyword
    listexclude="update|feature"
    #
    case "$1" in
        "country")
            readarray -t countrylist < <( nordvpn countries | tr -d '\r' | tr -d '-' | grep -v -i -E "$listexclude" | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort )
            if [[ "$2" == "count" ]]; then return; fi
            rcountry=$( printf '%s\n' "${countrylist[ RANDOM % ${#countrylist[@]} ]}" )
            countrylist+=( "Random" "Exit" )
            ;;
        "city")
            readarray -t citylist < <( nordvpn cities "$xcountry" | tr -d '\r' | tr -d '-' | grep -v -i -E "$listexclude" | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort )
            if [[ "$2" == "count" ]]; then return; fi
            rcity=$( printf '%s\n' "${citylist[ RANDOM % ${#citylist[@]} ]}" )
            if (( "${#citylist[@]}" > 1 )); then
                citylist+=( "Random" "Best" )
            fi
            citylist+=( "Exit" )
            ;;
        "group")
            readarray -t grouplist < <( nordvpn groups | tr -d '\r' | tr -d '-' | grep -v -i -E "$listexclude" | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort )
            grouplist+=( "Exit" )
            ;;
    esac
}
function country_names_modify {
    # Create the modcountrylist array.
    # Add an asterisk if the country is listed in the 'nordvirtual' array.
    # Shorten long names so the "Countries" menu fits better in the terminal window.
    #
    modcountrylist=()
    # iterate over elements in countrylist
    for mcountry in "${countrylist[@]}"
    do
        # Laos API/CLI name mismatch.  Strip the apostrophe for comparison.
        if [[ "$virtual" == "enabled" ]] && printf "%s\n" "${nordvirtual[@],,}" | tr -d "'" | grep -q -x -i "${mcountry,,}"; then
            # add an asterisk to the country name
            mcountry="${mcountry}*"
        fi
        # shorten long country names if the option is enabled
        if [[ -n "$charlimit" ]]; then
            # minimum is 6 characters.  Austra|lia  Austri|a
            if (( charlimit < 6 )); then charlimit="6"; fi
            #
            # special case
            mcountry="${mcountry/Lao_Peoples_Democratic_Republic/Laos}"
            #
            # general substitutions
            mcountry="${mcountry/United/Utd}"
            mcountry="${mcountry/North/N}"
            mcountry="${mcountry/South/S}"
            mcountry="${mcountry/Republic/Rep}"
            mcountry="${mcountry/_And_/+}"
            #
            # check if the country name has an asterisk at the end
            if [[ "${mcountry: -1}" == "*" ]]; then
                # check if the country name is longer than the character limit
                if (( ${#mcountry} > charlimit )); then
                    # shorten the country name to the limit minus one
                    shortened_country="${mcountry:0:$(( charlimit - 1 ))}"
                    # add the asterisk to the end
                    mcountry="${shortened_country}*"
                fi
            else
                # if there is no asterisk
                # check if the country name is longer than the limit
                if (( ${#mcountry} > charlimit )); then
                    # shorten the country name to match the limit
                    mcountry="${mcountry:0:$charlimit}"
                fi
            fi
        fi
        # add the modified country name to modcountrylist. includes "Random" "Exit"
        modcountrylist+=( "$mcountry" )
    done
}
function city_names_modify {
    # Create the modcitylist array.
    # Add an asterisk if the city is listed in the 'nordvirtual' array.
    #
    modcitylist=()
    for mcity in "${citylist[@]}"
    do
        if [[ "$virtual" == "enabled" ]] && printf "%s\n" "${nordvirtual[@],,}" | grep -q -x -i "${mcity,,}"; then
            # add an asterisk to the city name
            mcity="${mcity}*"
        fi
        # add the modified city name to modcitylist. includes "Random" "Best" "Exit"
        modcitylist+=( "$mcity" )
    done
}
function country_names_restore {
    # countrylist and modcountrylist store two names for the same country at the same index
    # in country_menu, xcountry is selected from modcountrylist (abbreviated and/or with asterisk)
    # find the original country name to use in function city_menu
    #
    # if xcountry is a valid country name then return
    for i in "${!countrylist[@]}"; do
        if [[ "${countrylist[i],,}" == "${xcountry,,}" ]]; then
            return
        fi
    done
    # iterate over modcountrylist to find the index
    for i in "${!modcountrylist[@]}"; do
        if [[ "${modcountrylist[i],,}" == "${xcountry,,}" ]]; then
            index=$i
            break
        fi
    done
    # restore the original country name from the countrylist array
    xcountry="${countrylist[index]}"
    #
}
function city_names_restore {
    # citylist and modcitylist store two names for the same city at the same index
    # in city_menu, xcity is selected from modcitylist (may have an asterisk)
    # find the original city name to make the VPN connection
    #
    # if xcity is a valid city name then return
    for i in "${!citylist[@]}"; do
        if [[ "${citylist[i],,}" == "${xcity,,}" ]]; then
            return
        fi
    done
    # iterate over modcitylist to find the index
    for i in "${!modcitylist[@]}"; do
        if [[ "${modcitylist[i],,}" == "${xcity,,}" ]]; then
            index=$i
            break
        fi
    done
    # restore the original city name from the citylist array
    xcity="${citylist[index]}"
    #
}
function virtual_note {
    # make a note if virtual servers are in the list
    # $1 = "${modcountrylist[@]}" or "${modcitylist[@]}"
    #
    # check if any element has an asterisk
    for astrx in "${@}"; do
        if [[ $astrx == *"*"* ]]; then
            echo -e "${FVColor}(*) = Virtual Servers${Color_Off}"
            echo
            break
        fi
    done
}
function country_menu {
    # submenu for all available countries
    #
    heading "Countries"
    parent="Main"
    create_list "country"
    country_names_modify
    #
    virtual_note "${modcountrylist[@]}"
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Countries with Obfuscation support"
        echo
    fi
    PS3=$'\n''Choose a Country: '
    select xcountry in "${modcountrylist[@]}"
    do
        parent_menu
        if [[ "$xcountry" == "Exit" ]]; then
            main_menu
        elif [[ "$xcountry" == "Random" ]]; then
            xcountry="$rcountry"
            city_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#modcountrylist[@]} )); then
            country_names_restore
            city_menu
        else
            invalid_option "${#modcountrylist[@]}" "$parent"
        fi
    done
}
function city_menu {
    # all available cities in $xcountry
    # $1 = parent menu name - valid options are listed in function parent_menu
    #      disables fast7 (automatic connect to country)
    #
    if [[ -n "$1" ]]; then
        parent="$1"
    else
        parent="Country"
    fi
    heading "$xcountry"
    echo
    if [[ "$fast7" =~ ^[Yy]$ ]] && [[ -z "$1" ]]; then
        echo -e "${FColor}Fast7 is enabled. Connect to the country not a city.${Color_Off}"
        echo
        echo -e "Connect to ${LColor}$xcountry${Color_Off}."
        disconnect_vpn
        nordvpn connect "$xcountry"
        status
        exit
    fi
    create_list "city"
    city_names_modify
    virtual_note "${modcitylist[@]}"
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Cities in $xcountry with Obfuscation support"
        echo
    fi
    PS3=$'\n''Connect to City: '
    select xcity in "${modcitylist[@]}"
    do
        parent_menu
        case $xcity in
            "Exit")
                main_menu
                ;;
            "Best")
                heading "$xcountry"
                disconnect_vpn
                echo "Connect to the best available city."
                echo
                nordvpn connect "$xcountry"
                status
                exit
                ;;
            "Random")
                heading "Random"
                disconnect_vpn
                echo "Connect to $rcity $xcountry"
                echo
                nordvpn connect "$rcity"
                status
                exit
                ;;
            *)
                if (( 1 <= REPLY )) && (( REPLY <= ${#modcitylist[@]} )); then
                    city_names_restore
                    heading "$xcity"
                    disconnect_vpn
                    echo "Connect to $xcity $xcountry"
                    echo
                    nordvpn connect "$xcity"
                    status
                    exit
                else
                    invalid_option "${#modcitylist[@]}" "$parent"
                fi
                ;;
        esac
    done
}
function city_count {
    # list all the available cities by using the Nord CLI
    #
    allcountries=()
    allcities=()
    virtualcountries=()
    virtualcities=()
    #
    create_list "country" "count"
    #
    heading "All Countries and Cities by using Nord CLI" "txt"
    # must use var "$xcountry" for command: create_list "city"
    for xcountry in "${countrylist[@]}"
    do
        virtualcountry="false"
        for element in "${nordvirtual[@]}"
        do
            if [[ "${element,,}" == "${xcountry,,}" ]]; then
                virtualcountry="true"
                echo "$xcountry*"
                allcountries+=( "$xcountry*" )
                virtualcountries+=( "$xcountry*" )
                break
            fi
        done
        if ! $virtualcountry; then
            echo "$xcountry"
            allcountries+=( "$xcountry" )
        fi
        create_list "city" "count"
        for ccity in "${citylist[@]}"
        do
            virtualcity="false"
            for element in "${nordvirtual[@]}"
            do
                if [[ "${element,,}" == "${ccity,,}" ]]; then
                    virtualcity="true"
                    echo "    $ccity*"
                    if $virtualcountry; then
                        virtualcities+=( "$xcountry* $ccity*" )
                        allcities+=( "$ccity* $xcountry*" )
                    else
                        virtualcities+=( "$xcountry $ccity*" )
                        allcities+=( "$ccity* $xcountry" )
                    fi
                    break
                fi
            done
            if ! $virtualcity; then
                echo "    $ccity"
                allcities+=( "$ccity $xcountry" )
            fi
        done
        echo
    done
    #
    #heading "All Countries" "txt"
    #printf '%s\n' "${allcountries[@]}" | sort
    #
    #heading "All Cities" "txt"
    #printf '%s\n' "${allcities[@]}" | sort
    #
    #heading "Virtual Countries" "txt"
    #printf '%s\n' "${virtualcountries[@]}" | sort
    #
    #heading "Virtual Cities" "txt"
    #printf '%s\n' "${virtualcities[@]}" | sort
    #
    echo
    echo "========================="
    echo "Total Countries    = ${#allcountries[@]}"
    echo "Total Cities       = ${#allcities[@]}"
    echo "Virtual Countries* = ${#virtualcountries[@]}"
    echo "Virtual Cities*    = ${#virtualcities[@]}"
    echo "========================="
    echo
    echo "(*) = The location is listed in the 'nordvirtual' array (line $(grep -m1 -n "nordvirtual=(" "$0" | cut -f1 -d':'))."
    echo
    if [[ "$virtual" == "disabled" ]]; then
        echo -e "$vl Virtual-Location is $virtualc."
        echo
    fi
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec."
        echo "These locations have Obfuscation support."
        echo
    fi
}
function host_connect {
    heading "Hostname"
    echo "Connect to specific servers by name."
    echo
    echo "This option may be useful to test multiple servers for"
    echo "latency, load, throughput, app compatibility, etc."
    echo -e "Modify ${LColor}function host_connect${Color_Off} to add test commands."
    echo
    echo "A list of servers can be found in:  Tools - NordVPN API"
    echo
    echo -e "${FColor}(Leave blank to quit)${Color_Off}"
    echo
    read -r -p "Enter the server name (eg. us9364): " connecthost
    if [[ -z $connecthost ]]; then
        echo -e "${DColor}(Skipped)${Color_Off}"
        echo
        return
    elif [[ "$connecthost" == *"socks"* ]]; then
        echo
        echo -e "${WColor}Unable to connect to SOCKS servers${Color_Off}"
        echo
        return
    elif [[ "$connecthost" == *"nord"* ]]; then
        connecthost=$( echo "$connecthost" | cut -f1 -d'.' )
    fi
    disconnect_vpn
    echo "Connect to $connecthost"
    echo
    nordvpn connect "$connecthost"
    status
    # add testing commands here
    #
    # https://streamtelly.com/check-netflix-region/
    echo "Netflix Region and Status"
    curl --silent "http://api-global.netflix.com/apps/applefuji/config" | grep -E 'geolocation.country|geolocation.status'
    echo
    #
}
function random_worldwide {
    # connect to a random city worldwide
    #
    create_list "country"
    xcountry="$rcountry"
    create_list "city"
    #
    heading "Random"
    echo "Connect to a random city worldwide."
    echo
    echo -e "${EColor}$rcity $rcountry${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        main_menu
    fi
    disconnect_vpn
    echo "Connect to $rcity $rcountry"
    echo
    nordvpn connect "$rcity"
    status
    exit
}
function killswitch_enable {
    echo
    if [[ "$firewall" == "disabled" ]]; then
        nordvpn set firewall enabled; wait
        echo
    fi
    nordvpn set killswitch enabled; wait
    echo
}
function killswitch_groups {
    if [[ "$killswitch" == "enabled" ]]; then return; fi
    #
    if [[ "$fast5" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}Fast5 is enabled.  Enabling the Kill Switch.${Color_Off}"
        killswitch_enable
    elif [[ "$exitkillswitch" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}(exitkillswitch) - Always enable the Kill Switch.${Color_Off}"
        killswitch_enable
    else
        if [[ "$firewall" == "disabled" ]]; then
            echo -e "${WColor}Enabling the Kill Switch will also enable the Firewall.${Color_Off}"
            echo
        fi
        change_setting "killswitch" "back"
    fi
}
function group_location {
    # $1 = $1 from function group_connect (Nord group name)
    #
    heading "Set Location" "txt" "alt"
    if [[ -n $location ]]; then
        echo -e "Default location ${EColor}$location${Color_Off} will be ignored."
        echo
    fi
    echo "The location must support $1."
    echo
    case "$1" in
        "Obfuscated_Servers")
            echo "For a list of supported locations, enable Obfuscate and visit:"
            echo "Tools - NordVPN API - All Cities"
            ;;
        "Double_VPN")
            echo "For a list of $1 server-pairs, visit:"
            echo "Tools - NordVPN API - All VPN Servers"
            ;;
        "Onion_Over_VPN")
            echo "Typically only Netherlands and Switzerland are available."
            echo "For a list of $1 servers, visit:"
            echo "Tools - NordVPN API - All VPN Servers"
            ;;
        "P2P")
            echo "(Any region should be OK)"
            ;;
        "Dedicated_IP")
            # https://support.nordvpn.com/hc/en-us/articles/19507808024209
            echo -e "${EColor}$1 locations (subject to change):${Color_Off}"
            echo "Buffalo Chicago Dallas Los_Angeles Miami New_York Seattle Toronto"
            echo "Amsterdam Brussels Copenhagen Frankfurt Lisbon London Madrid Milan"
            echo "Paris Stockholm Warsaw Zurich Hong_Kong Tokyo Sydney Johannesburg"
            ;;
    esac
    echo
    echo "Leave blank to have the app choose automatically."
    echo
    echo -e "${FColor}(Enter '$upmenu' to return to the $parent menu)${Color_Off}"
    echo
    read -r -p "Enter the $1 location: "
    parent_menu
    location="$REPLY"
    REPLY="y"
}
function group_connect {
    # $1 = Nord group name
    #
    parent="Group"
    case "$1" in
        "Obfuscated_Servers")
            heading "Obfuscated"
            echo "Obfuscated servers are specialized VPN servers that hide the fact"
            echo "that you’re using a VPN to reroute your traffic. They allow users"
            echo "to connect to a VPN even in heavily restrictive environments."
            location="$obwhere"
            ;;
        "Double_VPN")
            heading "Double-VPN"
            echo "Double VPN is a privacy solution that sends your internet traffic"
            echo "through two VPN servers, encrypting it twice."
            location="$dblwhere"
            ;;
        "Onion_Over_VPN")
            heading "Onion+VPN"
            echo "Onion over VPN is a privacy solution that sends your internet traffic"
            echo "through a VPN server and then through the Onion network."
            location="$torwhere"
            ;;
        "P2P")
            heading "Peer to Peer"
            echo "Peer to Peer - sharing information and resources directly without"
            echo "relying on a dedicated central server."
            location="$p2pwhere"
            ;;
        "Dedicated_IP")
            heading "Dedicated-IP"
            echo "Connect to your assigned server, or test the performance of the"
            echo "server group before purchasing a Dedicated-IP.  Please refer to:"
            echo "https://support.nordvpn.com/hc/en-us/articles/19507808024209"
            location="$dipwhere"
            ;;
    esac
    echo
    indicators_display "group"
    echo
    echo "To connect to the $1 group the following"
    echo "changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    if [[ "$1" == "Obfuscated_Servers" ]]; then
        echo "Disable Post-Quantum."
        echo "Set Technology to OpenVPN."
        echo "Choose the Protocol."
        echo "Set Obfuscate to enabled."
    elif [[ "$1" == "Dedicated_IP" ]]; then
        echo "Disable Post-Quantum."
        echo "Set Technology to OpenVPN."
        echo "Choose the Protocol."
        echo "Set Obfuscate to disabled."
    else
        echo "Choose the Technology & Protocol."
        echo "Set NordLynx Post-Quantum (choice)."
        echo "Set Obfuscate to disabled."
    fi
    echo "Enable the Kill Switch (choice)."
    echo -e "Connect to the $1 group ${EColor}$location${Color_Off}"
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${FColor}Fast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        echo -e "${LColor}(Type ${FIColor}S${LColor} to specify a location)${Color_Off}"
        echo
        read -n 1 -r -p "Proceed? (y/n/S) "; echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            group_location "$1"
        fi
    fi
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        case "$1" in
            "Obfuscated_Servers")
                if [[ "$postquantum" == "enabled" ]]; then nordvpn set post-quantum disabled; wait; echo; fi
                if [[ "$technology" == "nordlynx" ]]; then nordvpn set technology openvpn; wait; echo; fi
                protocol_ask
                if [[ "$obfuscate" == "disabled" ]]; then nordvpn set obfuscate enabled; wait; echo; fi
                ;;
            "Dedicated_IP")
                if [[ "$postquantum" == "enabled" ]]; then nordvpn set post-quantum disabled; wait; echo; fi
                if [[ "$technology" == "nordlynx" ]]; then nordvpn set technology openvpn; wait; echo; fi
                protocol_ask
                if [[ "$obfuscate" == "enabled" ]]; then nordvpn set obfuscate disabled; wait; echo; fi
                ;;
            *)
                technology_setting "back"
                if [[ "$obfuscate" == "enabled" ]]; then nordvpn set obfuscate disabled; wait; echo; fi
                ;;
        esac
        killswitch_groups
        echo -e "Connect to the $1 group ${EColor}$location${Color_Off}"
        echo
        if [[ -n $location ]]; then
            nordvpn connect --group "$1" "$location"
        else
            nordvpn connect --group "$1"
        fi
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function technology_setting {
    # $1 = "back" - skip the heading, ignore fast3, return
    #
    parent="Settings"
    if [[ "$1" != "back" ]]; then
        heading "Technology"
        echo
        disconnect_warning
        echo "OpenVPN is an open-source VPN protocol that is required"
        echo "for Obfuscated servers, a Dedicated-IP, and to use TCP."
        echo "Post-Quantum VPN is not compatible with OpenVPN."
        echo
        echo "NordLynx is built around the WireGuard VPN protocol"
        echo "and may be faster with less overhead."
        echo "NordLynx supports the use of Post-Quantum VPN."
        echo
    fi
    echo -e "Currently using $technologydc."
    if [[ "$technology" == "nordlynx" ]]; then
        echo -e "$pq Post-Quantum VPN is $postquantumc."
    fi
    echo
    if [[ "$fast3" =~ ^[Yy]$ ]] && [[ "$1" != "back" ]]; then
        echo -e "${FColor}Fast3 is enabled.  Changing the Technology.${Color_Off}"
        REPLY="y"
    elif [[ "$technology" == "openvpn" ]]; then
        read -n 1 -r -p "Change the Technology to NordLynx? (y/n) "; echo
    else
        read -n 1 -r -p "Change the Technology to OpenVPN? (y/n) "; echo
    fi
    parent_menu "$1"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        if [[ "$technology" == "openvpn" ]]; then
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
                echo
            fi
            if [[ "$protocol" == "TCP" ]]; then
                nordvpn set protocol UDP; wait
                echo
            fi
            nordvpn set technology nordlynx; wait
            echo
            set_vars
            change_setting "post-quantum" "back"
        else
            if [[ "$postquantum" == "enabled" ]]; then
                nordvpn set post-quantum disabled; wait
                echo
            fi
            nordvpn set technology openvpn; wait
            echo
            protocol_ask
        fi
    else
        echo
        echo -e "Continue to use $technologydc."
        echo
        set_vars
        if [[ "$connected" != "connected" ]]; then
            if [[ "$technology" == "openvpn" ]]; then
                protocol_ask
            elif [[ "$technology" == "nordlynx" ]]; then
                change_setting "post-quantum" "back"
            fi
        fi
    fi
    if [[ "$1" == "back" ]]; then
        set_vars
        echo
        return
    fi
    main_menu
}
function protocol_setting {
    heading "Protocol"
    parent="Settings"
    if [[ "$technology" == "nordlynx" ]]; then
        echo
        echo -e "Technology is currently set to $technologydc."
        echo
        echo "No protocol to specify when using $technologyd,"
        echo "WireGuard supports UDP only."
        echo
        echo "Change Technology to OpenVPN to use TCP or UDP."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting? (y/n) "; echo
        parent_menu
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            technology_setting
        else
            main_menu
        fi
    fi
    disconnect_warning
    echo "UDP is mainly used for online streaming and downloading."
    echo "TCP is more reliable but also slightly slower than UDP and"
    echo " is mainly used for web browsing."
    echo
    echo -e "The Protocol is set to $protocoldc."
    echo
    if [[ "$fast3" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}Fast3 is enabled.  Changing the Protocol.${Color_Off}"
        REPLY="y"
    elif [[ "$protocol" == "UDP" ]]; then
        read -n 1 -r -p "Change the Protocol to TCP? (y/n) "; echo
    else
        read -n 1 -r -p "Change the Protocol to UDP? (y/n) "; echo
    fi
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        if [[ "$protocol" == "UDP" ]]; then
            nordvpn set protocol TCP; wait
        else
            nordvpn set protocol UDP; wait
        fi
    else
        echo
        echo -e "Continue to use $protocoldc."
    fi
    main_menu
}
function protocol_ask {
    # Ask to choose TCP/UDP if changing to OpenVPN, using Obfuscate,
    # and when connecting to groups using OpenVPN
    #
    set_vars    # set $protocol if technology just changed from NordLynx
    echo -e "The Protocol is set to $protocoldc."
    echo
    if [[ "$fast6" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}Fast6 is enabled.  Always choose $fast6p.${Color_Off}"
        echo
        if [[ "$protocol" == "UDP" ]] && [[ "$fast6p" == "TCP" ]]; then
            nordvpn set protocol TCP; wait
            echo
        elif [[ "$protocol" == "TCP" ]] && [[ "$fast6p" == "UDP" ]]; then
            nordvpn set protocol UDP; wait
            echo
        fi
        return
    elif [[ "$protocol" == "UDP" ]]; then
        read -n 1 -r -p "Change the Protocol to TCP? (y/n) "; echo
    else
        read -n 1 -r -p "Change the Protocol to UDP? (y/n) "; echo
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$protocol" == "UDP" ]]; then
            nordvpn set protocol TCP; wait
        else
            nordvpn set protocol UDP; wait
        fi
        echo
    else
        echo -e "Continue to use $protocoldc."
        echo
    fi
}
function change_setting {
    # $1 = Nord command
    # $2 = "back" - ignore fast2, return
    #
    if [[ "$2" != "back" ]]; then
        parent="Settings"
    fi
    chgloc=""
    case "$1" in
        "firewall")             chgname="the Firewall"; chgvar="$firewall"; chgind="$fw";;
        "routing")              chgname="Routing"; chgvar="$routing"; chgind="$rt";;
        "analytics")            chgname="Analytics"; chgvar="$analytics"; chgind="$an";;
        "killswitch")           chgname="the Kill Switch"; chgvar="$killswitch"; chgind="$ks";;
        "threatprotectionlite") chgname="Threat Protection Lite"; chgvar="$tplite"; chgind="$tp";;
        "notify")               chgname="Notify"; chgvar="$notify"; chgind="$no";;
        "tray")                 chgname="the Tray"; chgvar="$tray"; chgind="$tr";;
        "autoconnect")          chgname="Auto-Connect"; chgvar="$autoconnect"; chgind="$ac"; chgloc="$acwhere2";;
        "ipv6")                 chgname="IPv6"; chgvar="$ipversion6"; chgind="$ip6";;
        "meshnet")              chgname="Meshnet"; chgvar="$meshnet"; chgind="$mn";;
        "lan-discovery")        chgname="LAN-Discovery"; chgvar="$landiscovery"; chgind="$ld";;
        "virtual-location")     chgname="Virtual-Location"; chgvar="$virtual"; chgind="$vl";;
        "post-quantum")         chgname="Post-Quantum VPN"; chgvar="$postquantum"; chgind="$pq";;
        *)                      echo; echo -e "${WColor}'$1' not defined${Color_Off}"; echo; return;;
    esac
    #
    if [[ "$chgvar" == "enabled" ]]; then
        chgvarc="${EColor}$chgvar${Color_Off}"
        chgprompt=$(echo -e "${DColor}Disable${Color_Off} $chgname? (y/n) ")
    else
        chgvarc="${DColor}$chgvar${Color_Off}"
        chgprompt=$(echo -e "${EColor}Enable${Color_Off} $chgname? (y/n) ")
    fi
    echo -e "$chgind $chgname is $chgvarc."
    echo
    if [[ "$fast2" =~ ^[Yy]$ ]] && [[ "$2" != "back" ]]; then
        echo -e "${FColor}Fast2 is enabled.  Changing the setting.${Color_Off}"
        REPLY="y"
        if [[ "$chgvar" == "enabled" ]] && [[ "$1" == "routing" ]]; then
            # confirmation prompt before disable routing
            echo
            read -n 1 -r -p "$(echo -e "Confirm: ${WColor}Disable $chgname${Color_Off} (y/n) ")"; echo
        fi
    else
        read -n 1 -r -p "$chgprompt"; echo
    fi
    parent_menu "$2"
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$chgvar" == "disabled" ]]; then
            case "$1" in
                "killswitch")
                    if [[ "$firewall" == "disabled" ]]; then
                        # when connecting to Groups or changing the setting from IPTables
                        echo -e "${WColor}Enabling the Firewall.${Color_Off}"
                        echo
                        nordvpn set firewall enabled; wait
                        echo
                    fi
                    ;;
                "threatprotectionlite")
                    if [[ "$customdns" != "disabled" ]]; then
                        nordvpn set dns disabled; wait
                        echo
                    fi
                    ;;
                "autoconnect")
                    if [[ -n $chgloc ]]; then
                        echo -e "$chgname to ${LColor}$chgloc${Color_Off}"
                        echo
                    fi
                    ;;
                "meshnet")
                    echo -e "${WColor}Wait 30s to refresh the peer list.${Color_Off}"
                    echo "Try disconnecting the VPN if Meshnet fails to enable."
                    echo
                    ;;
                "post-quantum")
                    if [[ "$connected" == "connected" ]]; then
                        echo -e "${WColor}Reconnect to VPN${Color_Off} to start using Post-Quantum encryption."
                        echo
                    fi
                    ;;
            esac
            #
            if [[ -n $chgloc ]]; then
                nordvpn set "$1" enabled "$chgloc"; wait
            else
                nordvpn set "$1" enabled; wait
            fi
            #
        else
            case "$1" in
                "firewall")
                    if [[ "$killswitch" == "enabled" ]]; then
                        # when changing the setting from IPTables
                        echo -e "${WColor}Disabling the Kill Switch.${Color_Off}"
                        echo
                        nordvpn set killswitch disabled; wait
                        echo
                    fi
                    ;;
                "routing")
                    echo -e "${WColor}Disabling all traffic routing.${Color_Off}"
                    echo
                    ;;
                "post-quantum")
                    if [[ "$connected" == "connected" ]]; then
                        echo -e "${WColor}Disconnect or reconnect to VPN${Color_Off} to stop using Post-Quantum encryption."
                        echo
                    fi
                    ;;
            esac
            #
            nordvpn set "$1" disabled; wait
            #
        fi
    else
        echo -e "$chgind Keep $chgname $chgvarc."
    fi
    if [[ "$2" == "back" ]]; then
        set_vars
        echo
        return
    fi
    main_menu
}
function firewall_setting {
    heading "Firewall"
    echo "Enable or Disable the NordVPN Firewall."
    echo "Enabling the Nord Firewall disables the Linux UFW."
    echo "The Firewall must be enabled to use the Kill Switch."
    echo
    echo -e "Firewall Mark: ${LColor}$fwmark${Color_Off}"
    # see:  https://linux.die.net/man/8/iptables
    echo "Change with: nordvpn set fwmark <mark>"
    echo
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "$fw the Firewall is $firewallc."
        echo
        echo -e "${WColor}The Kill Switch must be disabled before disabling the Firewall.${Color_Off}"
        echo
        change_setting "killswitch" "back"
        if [[ "$killswitch" == "enabled" ]]; then
            echo -e "$fw Keep the Firewall $firewallc."
            main_menu
        fi
    fi
    change_setting "firewall"
}
function routing_setting {
    heading "Routing"
    echo
    echo "Allows routing traffic through VPN servers (and peers in Meshnet)."
    echo
    echo -e "${FColor}Routing should typically be enabled.${Color_Off}"
    echo
    echo "If this setting is disabled, the app will connect to the"
    echo "VPN server (or peer) but won’t route any traffic."
    echo
    change_setting "routing"
}
function analytics_setting {
    heading "Analytics"
    echo
    echo "Help NordVPN improve by sending anonymous aggregate data: "
    echo "crash reports, OS version, marketing performance, and "
    echo "feature usage data. (Nothing that could identify you.)"
    echo
    change_setting "analytics"
}
function killswitch_setting {
    heading "Kill Switch"
    echo "Kill Switch is a feature helping you prevent unprotected access to"
    echo "the internet when your traffic doesn't go through a NordVPN server."
    echo
    echo "When the Kill Switch is enabled and the VPN is disconnected, your"
    echo "computer should not be able to access the internet."
    echo
    if [[ "$connected" != "connected" ]]; then
        echo -e "The VPN is currently $connectedc."
        echo
    fi
    if [[ "$firewall" == "disabled" ]]; then
        echo -e "$ks the Kill Switch is $killswitchc."
        echo
        echo -e "${WColor}The Firewall must be enabled to use the Kill Switch.${Color_Off}"
        echo
        change_setting "firewall" "back"
        if [[ "$firewall" == "disabled" ]]; then
            echo -e "$ks Keep the Kill Switch $killswitchc."
            main_menu
        fi
    fi
    change_setting "killswitch"
}
function tplite_setting {
    heading "TPLite"
    echo "Threat Protection Lite is a feature protecting you from ads, unsafe"
    echo "connections, and malicious sites. Previously known as CyberSec."
    echo "Uses the Nord Threat Protection Lite DNS 103.86.96.96 103.86.99.99"
    echo
    if [[ "$customdns" != "disabled" ]]; then
        echo -e "$dns Note: Enabling TPLite disables Custom-DNS"
        echo "      Current $dns_servers"
        echo
    fi
    change_setting "threatprotectionlite"
}
function notify_setting {
    heading "Notify"
    echo
    echo "Send OS notifications when the VPN status changes, and"
    echo "on Meshnet file transfer events."
    echo
    change_setting "notify"
}
function tray_setting {
    heading "Tray"
    echo
    echo "Enable or disable the NordVPN icon in the system tray."
    echo "The icon provides quick access to basic controls and VPN status details."
    echo
    change_setting "tray"
}
function autoconnect_setting {
    heading "AutoConnect"
    parent="Settings"
    echo "Automatically connect to the VPN on startup."
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob When obfuscate is enabled, the Auto-Connect"
        echo "     location must support obfuscation."
        echo
    fi
    if [[ "$autoconnect" == "disabled" ]]; then
        if [[ -n $acwhere ]]; then
            echo -e "${FColor}Default location: ${LColor}$acwhere${Color_Off}"
        else
            echo -e "${FColor}Default location: ${LColor}Automatic${Color_Off}"
        fi
        echo
        read -r -p "Specify a location or hit 'Enter' for default: "
        parent_menu
        acwhere2=${REPLY:-$acwhere}
        echo
    fi
    change_setting "autoconnect"
}
function ipv6_setting {
    heading "IPv6"
    echo "Enable or disable NordVPN IPv6 support."
    echo
    echo "Also refer to:"
    echo "https://support.nordvpn.com/hc/en-us/articles/20164669224337"
    echo "https://forums.linuxmint.com/viewtopic.php?p=2387296#p2387296"
    echo
    change_setting "ipv6"
}
function landiscovery_setting {
    heading "LAN-Discovery"
    echo
    echo "Access printers, TVs, and other devices on your LAN while connected to"
    echo "the VPN, using Meshnet traffic routing, or with the Kill Switch enabled."
    echo
    echo "Automatically allow traffic from these subnets:"
    echo "10.0.0.0/8  169.254.0.0/16  172.16.0.0/12  192.168.0.0/16"
    echo
    if [[ -n "${allowlist[*]}" ]]; then
        echo -e "${WColor}Note:${Color_Off} Enabling LAN-Discovery will remove private subnets from the allowlist."
        echo
        echo -e "$al Current Allowlist:"
        printf '%s\n' "${allowlist[@]}"
        echo
    fi
    change_setting "lan-discovery"
}
function virtual_setting {
    heading "Virtual-Location"
    echo
    echo "Enable or disable the use of virtual servers."
    echo
    echo "Virtual servers let you connect to more places worldwide."
    echo "Physical servers are placed outside the virtual location"
    echo "but are configured to use an IP address from that location."
    echo
    echo "Refer to: https://nordvpn.com/blog/new-nordvpn-virtual-servers/"
    echo
    change_setting "virtual-location"
}
function postquantum_setting {
    # disconnect VPN when changing setting.  https://github.com/NordSecurity/nordvpn-linux/issues/637
    # if $postquantum is enabled, the technology is NordLynx and Meshnet is disabled
    # $postquantum has no value when using OpenVPN
    heading "Post-Quantum"
    echo "When Post-Quantum VPN is enabled, your connection uses cutting-edge"
    echo "cryptography designed to resist quantum computer attacks."
    echo "Not compatible with OpenVPN or Meshnet.  Refer to:"
    echo "https://nordvpn.com/blog/nordvpn-linux-post-quantum-encryption-support/"
    echo
    if [[ "$connected" == "connected" ]] || [[ "$technology" == "openvpn" ]] || [[ "$meshnet" == "enabled" ]] ; then
        echo -e "$pq Post-Quantum VPN is $postquantumc."
        echo
        echo -e "The VPN is $connectedc."
        if [[ "$postquantum" == "enabled" ]]; then
            echo
            echo -e "${WColor}To disable Post-Quantum VPN you must disconnect from VPN.${Color_Off}"
        else
            echo -e "The Technology is set to $technologydc."
            echo -e "$mn Meshnet is $meshnetc."
            echo
            echo -e "${WColor}To enable Post-Quantum VPN you must disconnect from VPN and"
            echo -e "use NordLynx Technology with Meshnet disabled.${Color_Off}"
        fi
        echo
        echo
        read -n 1 -r -p "Proceed? (y/n) "; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            disconnect_vpn "force" "check_ks"
            if [[ "$technology" == "openvpn" ]]; then if [[ "$protocol" == "TCP" ]]; then nordvpn set protocol UDP; fi; nordvpn set technology nordlynx; fi
            if [[ "$meshnet" == "enabled" ]]; then nordvpn set meshnet disabled; fi
            set_vars
            echo
        else
            settings_menu
        fi
    fi
    change_setting "post-quantum"
}
function obfuscate_setting {
    # not available when using NordLynx
    # must disconnect/reconnect to change setting
    heading "Obfuscate"
    parent="Settings"
    if [[ "$technology" == "nordlynx" ]]; then
        echo -e "Technology is currently set to $technologydc."
        echo
        echo "Obfuscation is not available when using $technologyd."
        echo "Change Technology to OpenVPN to use Obfuscation."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting? (y/n) "; echo
        parent_menu
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            technology_setting
        else
            main_menu
        fi
    fi
    disconnect_warning
    echo "Obfuscated servers can bypass internet restrictions such"
    echo "as network firewalls.  They are recommended for countries"
    echo "with restricted access. "
    echo
    echo "Only certain NordVPN locations support obfuscation."
    echo
    echo "Recommend connecting to the 'Obfuscated' group or through"
    echo "'Countries' when Obfuscate is enabled.  Attempting to"
    echo "connect to unsupported locations will cause an error."
    echo
    echo -e "$ob Obfuscate is $obfuscatec."
    echo
    if [[ "$fast3" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}Fast3 is enabled.  Changing the setting.${Color_Off}"
        REPLY="y"
    elif [[ "$obfuscate" == "enabled" ]]; then
        read -n 1 -r -p "$(echo -e "${DColor}Disable${Color_Off} Obfuscate? (y/n) ")"; echo
    else
        read -n 1 -r -p "$(echo -e "${EColor}Enable${Color_Off} Obfuscate? (y/n) ")"; echo
    fi
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
        else
            nordvpn set obfuscate enabled; wait
        fi
        echo
        protocol_ask
    else
        echo
        echo -e "$ob Keep Obfuscate $obfuscatec."
    fi
    main_menu
}
function meshnet_prompt {
    echo
    case $1 in
        "allow")
            echo -e "Enter '${EColor}allow${Color_Off}' or '${DColor}deny${Color_Off}' and the hostname|nickname|IP|pubkey"
            echo
            ;;
        "enable")
            echo -e "Enter '${EColor}enable${Color_Off}' or '${DColor}disable${Color_Off}' and the hostname|nickname|IP|pubkey"
            echo
            ;;
        "IP")
            echo "Enter the hostname, nickname, IP address, or public_key."
            echo
            ;;
        "rename_peer")  # nordvpn meshnet peer nickname
            echo -e "Enter '${EColor}set${Color_Off}' hostname|nickname|IP|pubkey <new nickname>"
            echo -e "Or enter '${DColor}remove${Color_Off}' hostname|nickname|IP|pubkey"
            echo
            ;;
        "rename_host")  # nordvpn meshnet
            echo -e "Enter '${EColor}set nickname${Color_Off}' <new nickname>"
            echo -e "Or enter '${DColor}remove nickname${Color_Off}'"
            echo
            ;;
    esac
    echo -e "${FColor}(Leave blank to quit)${Color_Off}"
    echo
}
function meshnet_filter {
    heading "Peer Filter" "txt"
    parent="Meshnet"
    echo "Search your peer list by applying filters."
    echo
    echo "nordvpn meshnet peer list --filter <value>"
    echo
    echo -e "${FColor}(Enter '$upmenu' to return to the $parent menu)${Color_Off}"
    echo
    submpeer=("peer list" "peer refresh" "online" "offline" "internal" "external" "incoming-traffic-allowed" "allows-incoming-traffic" "routing-allowed" "allows-routing" "multiple filters" "Exit")
    select mpeer in "${submpeer[@]}"
    do
        parent_menu
        case $mpeer in
            "Exit")
                main_menu
                ;;
            "multiple filters")
                heading "Apply Multiple Filters" "txt"
                echo "Enter the desired filters separated by commas only (no spaces)."
                echo "Contradictory filters will give no results."
                echo
                echo "online                    offline"
                echo "internal                  external"
                echo "incoming-traffic-allowed  allows-incoming-traffic"
                echo "routing-allowed           allows-routing"
                meshnet_prompt
                read -r -p "nordvpn meshnet peer list --filter "
                if [[ -n $REPLY ]]; then
                    heading "$REPLY" "txt"
                    nordvpn meshnet peer list --filter $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "peer refresh")
                heading "nordvpn meshnet peer refresh" "txt"
                nordvpn meshnet peer refresh
                ;;
            "peer list")
                heading "nordvpn meshnet peer list" "txt"
                nordvpn meshnet peer list
                ;;
            *)
                if (( 1 <= REPLY )) && (( REPLY <= ${#submpeer[@]} )); then
                    heading "$mpeer" "txt"
                    nordvpn meshnet peer list --filter "$mpeer"
                else
                    invalid_option "${#submpeer[@]}" "$parent"
                fi
                ;;
        esac
    done
}
function meshnet_invite {
    heading "Invitations"
    parent="Meshnet"
    echo "Send and receive invitations to join a meshnet."
    echo
    subinv=("Invite List" "Invite Send" "Invite Accept" "Invite Deny" "Invite Revoke" "Exit")
    select inv in "${subinv[@]}"
    do
        parent_menu
        case $inv in
            "Invite List")
                heading "Invite List" "txt" "alt"
                echo "Display the list of all sent and received meshnet invitations."
                echo
                echo "nordvpn meshnet invite list"
                echo
                nordvpn meshnet invite list
                ;;
            "Invite Send")
                heading "Invite Send" "txt" "alt"
                echo "Send an invitation to join the mesh network."
                echo
                echo "Usage: nordvpn meshnet invite send [options] [email]"
                echo
                echo "Options:"
                echo "  --allow-incoming-traffic"
                echo "      Allow incoming traffic from the peer. (default: false)"
                echo "  --allow-traffic-routing"
                echo "      Allow the peer to route traffic through this device. (default: false)"
                echo "  --allow-local-network-access"
                echo "      Allow the peer access to the local network when routing. (default: false)"
                echo "  --allow-peer-send-files"
                echo "      Allow the peer to send you files. (default: false)"
                meshnet_prompt
                read -r -p "nordvpn meshnet invite send "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet invite send $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Invite Accept")
                heading "Invite Accept" "txt" "alt"
                echo "Accept an invitation to join the inviter's mesh network."
                echo
                echo "Usage: nordvpn meshnet invite accept [options] [email]"
                echo
                echo "Options:"
                echo "  --allow-incoming-traffic"
                echo "      Allow incoming traffic from the peer. (default: false)"
                echo "  --allow-traffic-routing"
                echo "      Allow the peer to route traffic through this device. (default: false)"
                echo "  --allow-local-network-access"
                echo "      Allow the peer access to the local network when routing. (default: false)"
                echo "  --allow-peer-send-files"
                echo "      Allow the peer to send you files. (default: false)"
                meshnet_prompt
                read -r -p "nordvpn meshnet invite accept "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet invite accept $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Invite Deny")
                heading "Invite Deny" "txt" "alt"
                echo "Deny an invitation to join the inviter's mesh network."
                echo
                echo "Enter the email address to deny."
                meshnet_prompt
                read -r -p "nordvpn meshnet invite deny "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet invite deny "$REPLY"
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Invite Revoke")
                heading "Invite Revoke" "txt" "alt"
                echo "Revoke a sent invitation."
                echo
                echo "Enter the email address to revoke."
                meshnet_prompt
                read -r -p "nordvpn meshnet invite revoke "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet invite revoke "$REPLY"
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#subinv[@]}" "$parent"
                ;;
        esac
    done
}
function meshnet_transfers {
    # list the current and completed meshnet file transfers
    if [[ "$1" == "incoming" ]]; then
        echo -e "${DLColor}"
        nordvpn fileshare list --incoming
        echo -e "${Color_Off}"
    elif [[ "$1" == "outgoing" ]]; then
        echo -e "${ULColor}"
        nordvpn fileshare list --outgoing
        echo -e "${Color_Off}"
    else
        echo -e "${DLColor}"
        nordvpn fileshare list --incoming
        echo -e "${ULColor}"
        nordvpn fileshare list --outgoing
        echo -e "${Color_Off}"
    fi
}
function meshnet_fileshare {
    heading "File Sharing"
    parent="Meshnet"
    echo "Send and receive files securely over Meshnet."
    echo "Peers must have file sharing permissions."
    echo "Transfers use the --background flag by default."
    echo
    submshare=("List Transfers" "List Files" "Clear History" "Send" "Accept" "Auto-Accept" "Cancel" "Notify" "Online Peers"  "Exit")
    select mshare in "${submshare[@]}"
    do
        parent_menu
        case $mshare in
            "List Transfers")
                heading "List Transfers" "txt"
                echo "Current and completed file transfers."
                meshnet_transfers
                ;;
            "List Files")
                heading "List Files" "txt"
                echo "List all the files within a transfer."
                meshnet_transfers
                echo "Enter the transfer id to list the individual files."
                meshnet_prompt
                read -r -p "nordvpn fileshare list "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn fileshare list "$REPLY"
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                echo
                ;;
            "Clear History")
                # syntax: https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html
                heading "Clear History" "txt"
                echo "Clear the file transfer history."
                meshnet_transfers
                echo "Enter the time period to clear eg. '1d 12h' or 'all'"
                meshnet_prompt
                read -r -p "nordvpn fileshare clear "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn fileshare clear $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                echo
                ;;
            "Send")
                heading "Fileshare Send" "txt"
                echo "Send files directly to a meshnet peer."
                echo
                echo "nordvpn fileshare send --background <peer> </path/file1> </path/file2>"
                #
                echo
                echo -e "${WColor}'fileshare send' is not fully working with the script.${Color_Off}"
                echo "Transfers will fail if there is a space in the path. (File not found)"
                echo "Workaround: Copy the output command and paste it in a new terminal window."
                #
                meshnet_prompt
                read -r -p "Enter the recipient hostname|nickname|IP|pubkey: " meshwhere
                if [[ -n "$meshwhere" ]]; then
                    echo
                    echo "Enter the full paths and filenames, or try dragging the"
                    echo "files from your file manager to this terminal window."
                    echo
                    read -r -p "Files: " meshfiles
                    if [[ -n "$meshfiles" ]]; then
                        echo
                        echo -e "${EColor}Output Command:${Color_Off}"
                        echo "nordvpn fileshare send --background $meshwhere $meshfiles"
                        echo
                        # error: "file not found" when this command is run from the script:
                        # nordvpn fileshare send --background "$meshwhere" $meshfiles
                        # issue explained here: https://redd.it/1224ed7
                        # workaround = remove all single quotes (/u/oh5nxo via reddit)
                        meshfiles=${meshfiles//\'}
                        #
                        # shellcheck disable=SC2086 # word splitting (multiple file input)
                        nordvpn fileshare send --background "$meshwhere" $meshfiles
                        meshnet_transfers "outgoing"
                    else
                        echo -e "${DColor}(Skipped)${Color_Off}"
                        echo
                    fi
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Accept")
                heading "Fileshare Accept" "txt"
                echo -e "Save to: ${H2Color}$meshnetdir${Color_Off}"
                meshnet_transfers "incoming"
                echo -e "Enter the transfer id to ${EColor}accept${Color_Off} or specify"
                echo "individual files with: <id> <file1> <file2>...​"
                meshnet_prompt
                read -r -p "nordvpn fileshare accept --path '$meshnetdir' --background "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn fileshare accept --path "$meshnetdir" --background $REPLY
                    meshnet_transfers "incoming"
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Auto-Accept")
                heading "Fileshare Auto-Accept" "txt"
                echo "Automatically accept file transfers from a specific peer without"
                echo "receiving a file transfer request."
                echo
                echo -e "${WColor}Note:${Color_Off} Automatic file transfers will download to"
                echo "\$XDG_DOWNLOAD_DIR ($XDG_DOWNLOAD_DIR) or \$HOME/Downloads ($HOME/Downloads)"
                meshnet_prompt "enable"
                read -r -p "nordvpn meshnet peer auto-accept "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer auto-accept $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Cancel")
                heading "Fileshare Cancel" "txt"
                echo "Cancel a current or pending transfer."
                meshnet_transfers
                echo -e "Enter the transfer id to ${DColor}cancel${Color_Off} or specify"
                echo "individual files with: <id> <file1> <file2>...​"
                meshnet_prompt
                read -r -p "nordvpn fileshare cancel "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn fileshare cancel $REPLY
                    meshnet_transfers
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Notify")
                heading "Notify" "txt"
                echo "Send OS notifications for Meshnet file transfer events."
                echo "Accept or Decline file transfers directly from the notification."
                echo
                change_setting "notify" "back"
                ;;
            "Online Peers")
                heading "Online Peers" "txt"
                echo "List all the peers that are currently online."
                echo
                nordvpn meshnet peer list --filter online
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submshare[@]}" "$parent"
                ;;
        esac
    done
}
function meshnet_menu {
    # $1 = parent menu name
    heading "Meshnet"
    if [[ -n "$1" ]]; then
        parent="$1"
    else
        parent="Main"
    fi
    echo "Using NordLynx, Meshnet lets you access devices over encrypted private"
    echo "  tunnels directly, instead of connecting to a VPN server."
    echo "With Meshnet enabled up to 10 devices using the NordVPN app with the"
    echo "  same account are linked automatically."
    echo "Connect up to 50 external devices by sending invitations."
    echo "  Connections with an external device are isolated as a private pair."
    echo
    echo -e "$mn Meshnet is $meshnetc."
    echo
    PS3=$'\n''Choose an option: '
    submesh=("Enable/Disable" "Peer List" "Peer Refresh" "Peer Online" "Peer Filter" "Peer Remove" "Peer Incoming" "Peer Routing" "Peer Local" "Peer FileShare" "Peer Connect" "Peer Rename" "Host Rename" "Invitations" "File Sharing" "Speed Tests" "Restart Service" "Support" "Exit")
    select mesh in "${submesh[@]}"
    do
        parent_menu
        case $mesh in
            "Enable/Disable")
                clear -x
                echo
                if [[ "$postquantum" == "enabled" ]]; then
                    echo -e "$pq Post-Quantum VPN is $postquantumc."
                    echo -e "${WColor}Meshnet is not compatible with Post-Quantum VPN.${Color_Off}"
                    echo "Disable Post-Quantum before enabling Meshnet."
                    echo
                    read -n 1 -r -p "Go to the 'Post-Quantum' setting? (y/n) "; echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        postquantum_setting
                    else
                        meshnet_menu
                    fi
                fi
                change_setting "meshnet" "back"
                meshnet_menu
                ;;
            "Peer List")
                heading "Peer List" "txt"
                echo "List all the peers in your meshnet."
                echo
                echo "nordvpn meshnet peer list"
                echo
                nordvpn meshnet peer list
                ;;
            "Peer Refresh")
                heading "Peer Refresh" "txt"
                echo "Refresh the meshnet in case it was not updated automatically."
                echo
                echo "nordvpn meshnet peer refresh"
                echo
                nordvpn meshnet peer refresh
                ;;
            "Peer Online")
                heading "Peer Online" "txt"
                echo "List all the peers that are currently online."
                echo
                echo "nordvpn meshnet peer list --filter online"
                echo
                nordvpn meshnet peer list --filter online
                ;;
            "Peer Filter")
                meshnet_filter
                ;;
            "Peer Remove")
                heading "Peer Remove" "txt"
                echo "Remove a peer from the meshnet."
                meshnet_prompt "IP"
                read -r -p "nordvpn meshnet peer remove "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer remove "$REPLY"
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Peer Incoming")
                heading "Peer Incoming" "txt"
                echo "Peers under the same account are automatically added to the meshnet."
                echo "Allow or Deny a meshnet peer's incoming traffic to this device."
                meshnet_prompt "allow"
                read -r -p "nordvpn meshnet peer incoming "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer incoming $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Peer Routing")
                heading "Peer Routing" "txt"
                echo "Allow or Deny a meshnet peer routing traffic through this device."
                meshnet_prompt "allow"
                read -r -p "nordvpn meshnet peer routing "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer routing $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Peer Local")
                heading "Peer Local" "txt"
                echo "Allow or Deny access to your local network when a peer is"
                echo "routing traffic through this device."
                meshnet_prompt "allow"
                read -r -p "nordvpn meshnet peer local "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer local $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Peer FileShare")
                heading "Peer FileShare" "txt"
                echo "Allow or Deny file sharing with a peer."
                meshnet_prompt "allow"
                read -r -p "nordvpn meshnet peer fileshare "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer fileshare $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Peer Connect")
                heading "Peer Connect" "txt"
                echo "Treats a peer like a VPN server and connects to it if the"
                echo "peer has allowed traffic routing."
                echo
                echo "You can route your traffic through one device at a time"
                echo "and only while using the NordLynx connection protocol."
                if [[ "$technology" != "nordlynx" ]]; then
                    echo
                    echo -e "Currently using $technologydc."
                fi
                meshnet_prompt "IP"
                read -r -p "nordvpn meshnet peer connect "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer connect "$REPLY"
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Peer Rename")
                heading "Peer Rename" "txt"
                echo "Assign a friendly nickname to a Meshnet peer."
                echo
                echo "Format: No spaces, max 25 characters (a-z, A-Z, 0-9)."
                echo "Single dash (-) allowed, but no dash at start or end."
                meshnet_prompt "rename_peer"
                read -r -p "nordvpn meshnet peer nickname "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer nickname $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Host Rename")
                heading "Host Rename" "txt"
                echo "Assign a friendly nickname to this device."
                echo
                echo "Format: No spaces, max 25 characters (a-z, A-Z, 0-9)."
                echo "Single dash (-) allowed, but no dash at start or end."
                meshnet_prompt "rename_host"
                read -r -p "nordvpn meshnet "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet $REPLY
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Invitations")
                meshnet_invite
                ;;
            "File Sharing")
                meshnet_fileshare
                ;;
            "Speed Tests")
                speedtest_iperf3 "Meshnet"
                ;;
            "Restart Service")
                heading "Restart Service" "txt"
                echo "Restarting the service may help resolve problems with populating"
                echo "the peer list or with excessively slow transfer speeds."
                echo
                read -n 1 -r -p "Disconnect the VPN and restart the nordvpnd service? (y/n) "; echo
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    disconnect_vpn "force" "check_ks"
                    restart_service "back"
                fi
                ;;
            "Support")
                heading "Support" "txt" "alt"
                openlink "https://meshnet.nordvpn.com/" "ask"
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submesh[@]}" "$parent"
                ;;
        esac
    done
}
function tplite_disable {
    echo
    if [[ "$tplite" == "enabled" ]]; then
        nordvpn set threatprotectionlite disabled
        echo
    fi
}
function customdns_menu {
    heading "CustomDNS"
    parent="Settings"
    echo "The NordVPN app automatically uses NordVPN DNS servers"
    echo "to prevent DNS leaks. (103.86.96.100 and 103.86.99.100)"
    echo "You can specify your own Custom-DNS servers instead."
    echo
    if [[ "$tplite" == "enabled" ]]; then
        echo -e "$tp Note: Enabling Custom-DNS disables TPLite"
        echo
    fi
    if [[ "$customdns" == "disabled" ]]; then
        echo -e "$dns Custom-DNS is ${DColor}disabled${Color_Off}."
    else
        echo -e "$dns Custom-DNS is ${EColor}enabled${Color_Off}."
        echo "Current $dns_servers"
    fi
    echo
    PS3=$'\n''Choose an option: '
    # Note submcdns[@] - new entries should keep the same format for the "Test Servers" option
    # eg Name<space>DNS1<space>DNS2
    submcdns=("Nord 103.86.96.100 103.86.99.100" "Nord-TPLite 103.86.96.96 103.86.99.99" "OpenDNS 208.67.220.220 208.67.222.222" "CB-Security 185.228.168.9 185.228.169.9" "AdGuard 94.140.14.14 94.140.15.15" "Quad9 9.9.9.9 149.112.112.11" "Cloudflare 1.0.0.1 1.1.1.1" "Google 8.8.4.4 8.8.8.8" "Specify or Default" "Disable Custom-DNS" "Flush DNS Cache" "Test Servers" "Exit")
    select cdns in "${submcdns[@]}"
    do
        parent_menu
        case $cdns in
            "Nord 103.86.96.100 103.86.99.100")
                tplite_disable
                nordvpn set dns 103.86.96.100 103.86.99.100
                ;;
            "Nord-TPLite 103.86.96.96 103.86.99.99")
                tplite_disable
                nordvpn set dns 103.86.96.96 103.86.99.99
                ;;
            "OpenDNS 208.67.220.220 208.67.222.222")
                tplite_disable
                nordvpn set dns 208.67.220.220 208.67.222.222
                ;;
            "CB-Security 185.228.168.9 185.228.169.9")
                # Clean Browsing Security 185.228.168.9 185.228.169.9
                # Clean Browsing Adult 185.228.168.10 185.228.169.11
                # Clean Browsing Family 185.228.168.168 185.228.169.168
                tplite_disable
                nordvpn set dns 185.228.168.9 185.228.169.9
                ;;
            "AdGuard 94.140.14.14 94.140.15.15")
                tplite_disable
                nordvpn set dns 94.140.14.14 94.140.15.15
                ;;
            "Quad9 9.9.9.9 149.112.112.11")
                tplite_disable
                nordvpn set dns 9.9.9.9 149.112.112.11
                ;;
            "Cloudflare 1.0.0.1 1.1.1.1")
                tplite_disable
                nordvpn set dns 1.0.0.1 1.1.1.1
                ;;
            "Google 8.8.4.4 8.8.8.8")
                tplite_disable
                nordvpn set dns 8.8.4.4 8.8.8.8
                ;;
            "Specify or Default")
                echo
                echo "Enter the DNS server IPs or hit 'Enter' for default."
                echo -e "Default: ${FColor}$dnsdesc ($default_dns)${Color_Off}"
                echo
                read -r -p "Up to 3 DNS server IPs: "
                parent_menu
                dns3srvrs="$REPLY"
                dns3srvrs=${dns3srvrs:-$default_dns}
                tplite_disable
                # shellcheck disable=SC2086 # word splitting eg. "1.1.1.1 1.0.0.1 8.8.8.8"
                nordvpn set dns $dns3srvrs
                echo
                ;;
            "Disable Custom-DNS")
                echo
                nordvpn set dns disabled; wait
                echo
                ;;
            "Flush DNS Cache")
                echo
                if command -v "resolvectl" &> /dev/null; then
                    sudo echo
                    sudo resolvectl statistics | grep "Current Cache Size"
                    echo -e "${WColor}  == Flush ==${Color_Off}"
                    sudo resolvectl flush-caches
                    sudo resolvectl statistics | grep "Current Cache Size"
                else
                    echo -e "${WColor}resolvectl not found${Color_Off}"
                    echo "For alternate methods see: https://nordvpn.com/blog/flush-dns/"
                fi
                echo
                ;;
            "Test Servers")
                echo
                echo "Specify a Hostname to lookup. "
                read -r -p "Hit 'Enter' for [$default_dnshost]: " testhost
                testhost=${testhost:-$default_dnshost}
                echo
                echo -e "${EColor}timeout 5 dig @<DNS> $testhost${Color_Off}"
                for i in "${submcdns[@]}"
                do
                    dnsheader=$( echo "$i" | cut -f1 -d' ' )
                    dnsip1=$( echo "$i" | cut -f2 -d' ' )
                    dnsip2=$( echo "$i" | cut -f3 -d' ' )
                    if [[ $dnsip1 =~ [0-9] ]]; then     # contains numbers
                        echo
                        echo -e "${LColor}===== $dnsheader =====${Color_Off}"
                        echo "$dnsip1 $( timeout 5 dig @"$dnsip1" "$testhost" | grep -i "Query time" | cut -f3 -d';' )"
                        echo "$dnsip2 $( timeout 5 dig @"$dnsip2" "$testhost" | grep -i "Query time" | cut -f3 -d';' )"
                    fi
                done
                echo
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submcdns[@]}" "$parent"
                ;;
        esac
        set_vars
    done
}
function allowlist_setting {
    # $1 = "back" - return
    #
    heading "Allowlist"
    parent="Settings"
    echo "Restore a default allowlist after installation, using 'Reset' or"
    echo "making other changes. Edit the script to modify the function."
    echo
    if [[ "$landiscovery" == "enabled" ]]; then
        echo -e "$ld Note: Allowlisting a private subnet is not available while"
        echo -e "     LAN-Discovery is enabled."
        echo
    fi
    echo -e "${EColor}Current Settings:${Color_Off}"
    if [[ -n "${allowlist[*]}" ]]; then
        echo -ne "$al "
        printf '%s\n' "${allowlist[@]}"
    else
        echo -e "$al No allowlist entries."
    fi
    echo
    echo -e "${LColor}function allowlist_commands${Color_Off}"
    startline=$(grep -m1 -n "allowlist_start" "$0" | cut -f1 -d':')
    endline=$(( $(grep -m1 -n "allowlist_end" "$0" | cut -f1 -d':') - 1 ))
    numlines=$(( endline - startline ))
    if app_exists "highlight"; then
        highlight -l -O xterm256 "$0" | head -n "$endline" | tail -n "$numlines"
    else
        cat -n "$0" | head -n "$endline" | tail -n "$numlines"
    fi
    echo
    echo -e "Type ${WColor}C${Color_Off} to clear the current allowlist."
    echo -e "Type ${FIColor}E${Color_Off} to edit the script."
    echo
    read -n 1 -r -p "Apply your default allowlist settings? (y/n/C/E) "; echo
    parent_menu "$1"
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        allowlist_commands
        set_vars
    elif [[ $REPLY =~ ^[Cc]$ ]]; then
        nordvpn allowlist remove all
        set_vars
    elif [[ $REPLY =~ ^[Ee]$ ]]; then
        echo -e "Modify ${LColor}function allowlist_commands${Color_Off} starting on ${FColor}line $(( startline + 1 ))${Color_Off}"
        echo
        openlink "$0" "noask" "exit"
    else
        echo "No changes made."
    fi
    if [[ -n "${allowlist[*]}" ]]; then
        echo
        echo -ne "$al "
        printf '%s\n' "${allowlist[@]}"
    fi
    if [[ "$1" == "back" ]]; then
        echo
        return
    fi
    main_menu
}
function login_check {
    if nordvpn account | grep -q -i "not logged in"; then
        echo -e "${WColor}** You are not logged in. **${Color_Off}"
        echo
        read -n 1 -r -p "Log in with a token? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            login_token
            return
        fi
        read -n 1 -r -p "Log in with the web browser? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            login_browser
        fi
    else
        echo -e "${EColor}You are logged in.${Color_Off}"
        echo
        nordvpn account
        echo
    fi
}
function login_token {
    heading "Login (token)" "txt"
    echo "To create a token, login to your Nord Account and navigate to:"
    echo "Services - NordVPN - Manual Setup - Generate New Token"
    echo
    echo -e "${LColor}https://my.nordaccount.com/${Color_Off}"
    echo
    echo -e "${FColor}(Leave blank to quit)${Color_Off}"
    echo
    read -r -p "Enter the login token: " logintoken
    if [[ -z $logintoken ]]; then
        echo -e "${DColor}(Skipped)${Color_Off}"
    else
        echo
        echo -e "${LColor}nordvpn login --token '$logintoken'${Color_Off}"
        echo
        nordvpn login --token "$logintoken"
    fi
    echo
    nordvpn account
    echo
}
function login_browser {
    heading "Login (browser)" "txt"
    nordvpn login
    echo
    echo "Provide the Callback URL if necessary or"
    echo "just hit Enter after login is complete."
    echo
    read -r -p "Callback URL: " callbackurl
    if [[ -z $callbackurl ]]; then
        echo -e "${DColor}(Skipped)${Color_Off}"
    else
        echo
        echo -e "${LColor}nordvpn login --callback '$callbackurl'${Color_Off}"
        echo
        nordvpn login --callback "$callbackurl"
    fi
    echo
    nordvpn account
    echo
}
function login_nogui {
    heading "Login (no GUI)" "txt"
    echo "Also see: Login (token)"
    echo
    echo -e "${EColor}Nord Account login without a GUI ('man nordvpn' Note 2)${Color_Off}"
    echo
    echo -e "${EColor}SSH${Color_Off} = in the SSH session connected to the device"
    echo -e "${FColor}Computer${Color_Off} = on the computer you're using to SSH into the device"
    echo
    echo -e "${EColor}  SSH${Color_Off}"
    echo "      1. Run 'nordvpn login' and copy the URL"
    echo -e "${FColor}  Computer${Color_Off}"
    echo "      2. Open the copied URL in your web browser"
    echo "      3. Complete the login procedure"
    echo "      4. Right click on the 'Continue' button and select 'Copy link'"
    echo -e "${EColor}  SSH${Color_Off}"
    echo "      5. Run 'nordvpn login --callback \"<copied link>\"'"
    echo "      6. Run 'nordvpn account' to verify that the login was successful"
    echo
}
function logout_nord {
    # use "--persist-token" flag if available (v3.16.0+)
    # https://github.com/NordSecurity/nordvpn-linux/issues/8
    #
    if nordvpn logout --help | grep -q -i "persist-token"; then
        echo -e "${LColor}nordvpn logout --persist-token${Color_Off}"
        echo
        nordvpn logout --persist-token
    else
        echo -e "${LColor}nordvpn logout${Color_Off}"
        echo
        nordvpn logout
    fi
    wait
    echo
}
function account_menu {
    heading "Account"
    parent="Settings"
    echo
    PS3=$'\n''Choose an option: '
    submacct=("Login Check" "Login (browser)" "Login (token)" "Login (no GUI)" "Logout" "Account Info" "Register" "Changelog" "Nord Version" "Nord Manual" "Nord GitHub" "Nord Repo" "NordAccount" "Support" "Exit")
    select acc in "${submacct[@]}"
    do
        parent_menu
        case $acc in
            "Login Check")
                echo
                login_check
                ;;
            "Login (browser)")
                login_browser
                ;;
            "Login (token)")
                login_token
                ;;
            "Login (no GUI)")
                login_nogui
                ;;
            "Logout")
                echo
                disconnect_vpn "force" "check_ks"
                logout_nord
                set_vars
                ;;
            "Account Info")
                echo
                nordvpn account
                echo
                ;;
            "Register")
                echo
                echo "Registers a new account."
                echo
                echo "Need to disconnect the VPN."
                echo
                echo -e "${WColor}** Untested **${Color_Off}"
                echo
                read -n 1 -r -p "Proceed? (y/n) "; echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    disconnect_vpn "force" "check_ks"
                    nordvpn register
                fi
                ;;
            "Changelog")
                echo
                zless -p"\($(nordvpn --version | cut -f3 -d' ')\)" "$nordchangelog"
                openlink "https://nordvpn.com/blog/nordvpn-linux-release-notes" "ask"
                ;;
            "Nord Version")
                echo
                nordvpn --version
                ;;
            "Nord Manual")
                echo
                man nordvpn
                ;;
            "Nord GitHub")
                echo
                openlink "https://github.com/NordSecurity/nordvpn-linux" "ask"
                ;;
            "Nord Repo")
                echo
                openlink "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/" "ask"
                ;;
            "NordAccount")
                echo
                openlink "https://my.nordaccount.com/" "ask"
                ;;
            "Support")
                heading "Support" "txt"
                echo -e "${H2Color}Contact${Color_Off}"
                echo "email: support@nordvpn.com"
                echo "https://support.nordvpn.com/"
                echo "https://nordvpn.com/contact-us/"
                echo
                echo -e "${H2Color}Terms of Service${Color_Off}"
                echo "https://my.nordaccount.com/legal/terms-of-service/"
                echo
                echo -e "${H2Color}Privacy Policy${Color_Off}"
                echo "https://my.nordaccount.com/legal/privacy-policy/"
                echo
                echo -e "${H2Color}Transparency Reports${Color_Off}"
                echo "https://nordvpn.com/blog/nordvpn-introduces-transparency-reports/"
                echo
                echo -e "${H2Color}Bug Bounty${Color_Off}"
                echo "https://hackerone.com/nordsecurity?type=team"
                echo
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submacct[@]}" "$parent"
                ;;
        esac
    done
}
function restart_service {
    # $1 = "back" - no heading, no prompt, return
    #
    parent="Settings"
    if [[ "$1" != "back" ]]; then
        heading "Restart"
        echo "Restart the nordvpnd service."
        echo
    fi
    echo "Send command:"
    echo -e "${WColor}sudo systemctl restart nordvpnd.service${Color_Off}"
    echo
    if [[ "$1" == "back" ]]; then
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "; echo
        echo
    fi
    parent_menu "$1"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl restart nordvpnd.service
        echo
        echo "Please wait 10s."
        echo
        countdown_timer "10"
    fi
    if [[ "$1" == "back" ]]; then
        set_vars
        echo
        return
    fi
    main_menu
    #
    # nordvpn.service, norduserd, nordfileshared
}
function reset_app {
    heading "Reset Nord"
    parent="Settings"
    echo
    echo "Reset the NordVPN app to default settings."
    echo "Requires NordVPN Account login to reconnect."
    echo
    echo -n "Send commands:"
    echo -e "${WColor}"
    echo "nordvpn set killswitch disabled"
    echo "nordvpn disconnect"
    echo "nordvpn logout"
    echo "nordvpn allowlist remove all"
    echo "nordvpn set defaults"
    echo "Restart nordvpnd service"
    echo "nordvpn login"
    echo "Apply your default configuration"
    echo -e "${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # first four redundant
        if [[ "$killswitch" == "enabled" ]]; then
            nordvpn set killswitch disabled; wait
        fi
        disconnect_vpn "force"
        logout_nord
        nordvpn allowlist remove all; wait
        echo
        nordvpn set defaults; wait
        echo
        echo -e "${EColor}Can also delete:${Color_Off}"
        echo "  /home/username/.config/nordvpn/nordvpn.conf"
        echo "  /var/lib/nordvpn/data/settings.dat"
        echo
        echo -e "${WColor}** Reminder **${Color_Off}"
        echo -e "${LColor}Reconfigure the allowlist and other settings.${Color_Off}"
        echo
        read -n 1 -s -r -p "Press any key to restart the service..."; echo
        echo
        restart_service "back"
        echo
        login_check
        echo
        set_defaults_ask
    fi
    main_menu
}
function iptables_status {
    echo
    echo -e "The VPN is $connectedc. IP: ${IPColor}$ipaddr${Color_Off}"
    echo -e "$fw The Firewall is $firewallc. Firewall Mark: ${LColor}$fwmark${Color_Off}"
    echo -e "$rt Routing is $routingc."
    echo -e "$ks The Kill Switch is $killswitchc."
    echo -e "$mn Meshnet is $meshnetc."
    echo -e "$ld LAN-Discovery is $landiscoveryc."
    if [[ -n "${allowlist[*]}" ]]; then
        echo -ne "$al "
        printf '%s\n' "${allowlist[@]}"
    else
        echo -e "$al No allowlist entries."
    fi
    echo
    echo -e "${LColor}sudo iptables -S${Color_Off}"
    sudo iptables -S
    echo
    COLUMNS="$menuwidth"
}
function iptables_flush {
    echo
    echo -e "${WColor}Flush the IPTables and clear all of your Firewall rules.${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "No changes made."
        echo
        return
    fi
    # https://www.cyberciti.biz/tips/linux-iptables-how-to-flush-all-rules.html
    echo
    echo -e "${LColor}IPTables Before:${Color_Off}"
    sudo iptables -S
    echo
    echo -e "${WColor}Flushing the IPTables${Color_Off}"
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
    echo
    echo -e "${EColor}IPTables After:${Color_Off}"
    sudo iptables -S
    echo
    echo -e "${FColor}Restart the service and reconnect to recreate the iptables rules.${Color_Off}"
    echo
}
function iptables_menu {
    heading "IPTables"
    parent="Settings"
    echo "Flushing the IPTables may help resolve problems enabling or"
    echo "disabling the KillSwitch or with other connection issues."
    echo
    echo -e "${WColor}** WARNING **${Color_Off}"
    echo "  - This will CLEAR all of your Firewall rules"
    echo "  - Review 'function iptables_flush' before use"
    echo "  - Commands require 'sudo'"
    echo
    PS3=$'\n''Choose an option: '
    submipt=("View IPTables" "Firewall" "Routing" "KillSwitch" "Meshnet" "LAN-Discovery" "Allowlist" "Flush IPTables" "Restart Service" "Ping Google" "Disconnect" "Exit")
    select ipt in "${submipt[@]}"
    do
        parent_menu
        case $ipt in
            "View IPTables")
                set_vars
                iptables_status
                ;;
            "Firewall")
                echo
                change_setting "firewall" "back"
                iptables_status
                ;;
            "Routing")
                echo
                change_setting "routing" "back"
                iptables_status
                ;;
            "KillSwitch")
                echo
                change_setting "killswitch" "back"
                iptables_status
                ;;
            "Meshnet")
                echo
                change_setting "meshnet" "back"
                iptables_status
                ;;
            "LAN-Discovery")
                echo
                change_setting "lan-discovery" "back"
                iptables_status
                ;;
            "Allowlist")
                echo
                allowlist_setting "back"
                iptables_status
                ;;
            "Flush IPTables")
                iptables_flush
                ;;
            "Restart Service")
                echo
                echo "Recreate the Nord iptables rules by restarting the service"
                echo "and reconnecting the VPN."
                echo
                read -n 1 -r -p "Disconnect the VPN and restart the service? (y/n) "; echo
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [[ "$autoconnect" == "enabled" ]]; then
                        change_setting "autoconnect" "back"
                    fi
                    disconnect_vpn "force"
                    restart_service "back"
                    iptables_status
                    ping_host "google.com" "show"
                fi
                ;;
            "Ping Google")
                iptables_status
                ping_host "google.com" "show"
                ;;
            "Disconnect")
                echo
                if [[ "$connected" == "connected" ]]; then
                    read -n 1 -r -p "$(echo -e "${WColor}Disconnect the VPN?${Color_Off} (y/n) ")"; echo
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        disconnect_vpn "force"
                    fi
                fi
                set_vars
                iptables_status
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submipt[@]}" "$parent"
                ;;
        esac
    done
}
function service_logs {
    heading "Service Logs"
    parent="Settings"
    echo
    if [[ -f "$nordlogfile" ]]; then
        echo -e "${EColor}$(basename "$nordlogfile")${Color_Off} already exists."
        echo
        backup_file "$nordlogfile"
    fi
    read -n 1 -r -p "Generate new log file: $(echo -e "${EColor}$nordlogfile${Color_Off}") ? (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${LColor}journalctl -u nordvpnd > '$nordlogfile'${Color_Off}"
        journalctl -u nordvpnd > "$nordlogfile"
        echo
        echo -e "${EColor}Completed $( wc -l < "$nordlogfile" ) lines \u2705${Color_Off}" # unicode checkmark
        echo
    fi
    echo
    echo "Last $loglines lines:"
    echo -e "${LColor}journalctl -u nordvpnd | tail -n $loglines${Color_Off}"
    echo
    journalctl -u nordvpnd | tail -n "$loglines"
    echo
    echo
    # priority 4 (warning) or more severe
    # Note that "[Warning] TELIO" log entries appear to be Priority 6 and won't be listed
    echo "Warnings and Errors:"
    echo -e "${LColor}journalctl -u nordvpnd -p 0..4${Color_Off}"
    echo
    journalctl -u nordvpnd -p 0..4
    echo
    echo
    if [[ -f "$nordlogfile" ]]; then
        openlink "$nordlogfile" "ask"
    else
        read -n 1 -s -r -p "Press any key to continue... "; echo
    fi
    settings_menu
}
function rate_server {
    while true
    do
        echo "How would you rate your connection quality?"
        echo -e "${DColor}Terrible${Color_Off} <_1__2__3__4__5_> ${EColor}Excellent${Color_Off}"
        echo
        read -n 1 -r -p "$(echo -e "Rating 1-5 [e${LColor}x${Color_Off}it]: ")" rating
        if [[ $rating =~ ^[Xx]$ ]] || [[ -z $rating ]]; then
            echo -e "${DColor}(Skipped)${Color_Off}"
            break
        elif (( 1 <= rating )) && (( rating <= 5 )); then
            echo; echo
            nordvpn rate "$rating"
            break
        else
            echo; echo
            echo -e "${WColor}** Please choose a number from 1 to 5${Color_Off}"
            echo "('Enter' or 'x' to exit)"
        fi
        echo
    done
}
function server_load {
    if [[ "$nordhost" == *"onion"* ]] || "$meshrouting"; then
        echo -e "${LColor}$nordhost${Color_Off} - Unable to check the server load."
        echo
        return
    fi
    echo -ne "$nordhost load = "
    # this will also work but it will download 20MB every time and possible api server timeouts
    # sload=$( timeout 10 curl --silent "https://api.nordvpn.com/v1/servers?limit=999999" | jq --arg host "$nordhost" '.[] | select(.hostname == $host) | .load' )
    #
    #
    # workaround.  https://github.com/ph202107/nordlist/issues/6
    if [[ -f "$nordserversfile" ]]; then
        # have not found a way to query the api directly by "hostname", but "id" works
        # find the "id" of the current server from the local .json
        serverid=$( jq --arg host "$nordhost" '.[] | select(.hostname == $host) | .id' "$nordserversfile" )
        if [[ -n "$serverid" ]]; then
            # query the api by the server id. this method downloads about 3KB instead of 20MB
            sload=$( timeout 10 curl --silent "https://api.nordvpn.com/v1/servers?limit=1&filters\[servers.id\]=$serverid" | jq '.[].load' )
        else
            # servers may be added or removed
            echo -e "${WColor}No id found for '$nordhost'${Color_Off}"
            echo "Try updating $(basename "$nordserversfile") (Tools - NordVPN API - All VPN Servers)"
        fi
    else
        echo -e "${WColor}$nordserversfile not found${Color_Off}"
        echo "Create the file at: Tools - NordVPN API - All VPN Servers"
    fi
    #
    if [[ -z $sload ]]; then
        echo "Request failed."
    elif (( sload <= 30 )); then
        echo -e "${EIColor}$sload%${Color_Off}"
    elif (( sload <= 60 )); then
        echo -e "${FIColor}$sload%${Color_Off}"
    else
        echo -e "${DIColor}$sload%${Color_Off}"
    fi
    echo
}
function backup_file {
    # $1 = full path and filename.  "$nordserversfile"  "$nordfavoritesfile" "$nordlogfile"
    #
    if [[ ! -f "$1" ]]; then return; fi
    #
    backupfile="$1.$(date -r "$1" +"%Y%m%d")"
    directory=$(dirname "$1")
    # everything before the final period.  used for search
    filename=$(basename "$1" | rev | cut -f2- -d '.' | rev)
    # search the directory for filename*
    existfiles=$(find "$directory" -type f -name "$filename*" | sort)
    #
    echo -e "File: ${EColor}$1${Color_Off}"
    echo "File Size: $( du -k "$1" | cut -f1 ) KB"
    echo "Last Modified: $( date -r "$1" )"
    #
    if [[ "$1" == "$nordserversfile" ]]; then
        echo "Server Count: $( jq length "$1" )"
    elif [[ "$1" == "$nordfavoritesfile" ]]; then
        echo "Server Count: $( wc -l < "$1" )"
    else
        echo "Lines: $( wc -l < "$1" )"
    fi
    echo
    # list the backups that are in the same directory
    echo -e "All ${LColor}$filename*${Color_Off} files in ${LColor}$directory${Color_Off}:"
    echo "$existfiles"
    echo
    read -n 1 -r -p "Backup as $(echo -e "${FColor}$backupfile${Color_Off}") ? (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "$backupfile" ]]; then
            read -n 1 -r -p "$(echo -e "${WColor}Already exists!${Color_Off}") Overwrite? (y/n) "; echo
            echo
            parent_menu
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp -v "$1" "$backupfile"
                echo
            fi
        else
            cp -v "$1" "$backupfile"
            echo
        fi
    fi
}
function favorites_verify {
    parent="Favorites"
    heading "Check for Obsolete Favorites" "txt"
    echo -e "Compare: ${EColor}$nordfavoritesfile${Color_Off}"
    echo "Last Modified: $( date -r "$nordfavoritesfile" )"
    echo -e "Against: ${EColor}$nordserversfile${Color_Off}"
    echo "Last Modified: $( date -r "$nordserversfile" )"
    echo
    echo "Check if any hostnames have been removed from service."
    echo "You will be prompted to delete any obsolete servers from"
    echo "the favorites list."
    echo
    echo "============================================================"
    echo "Backup and update the JSON file."
    echo "Recommended if you've added favorites since the last update."
    echo
    if [[ ! -f "$nordserversfile" ]]; then
        echo -e "${WColor}$(basename "$nordserversfile") does not exist.${Color_Off}"
        echo
        echo "Please visit: Tools - NordVPN API - All VPN Servers"
        echo
        return
    fi
    allservers_update
    echo
    echo "============================================================"
    echo "Please backup your favorites file."
    echo
    backup_file "$nordfavoritesfile"
    echo
    echo "============================================================"
    echo "Comparing your favorites with $(basename "$nordserversfile"):"
    echo
    # extract hostnames.  this speeds up the process significantly since we only search the json once
    hostnames="$(jq -r '.[].hostname' "$nordserversfile")"
    #
    # loop through lines in nordfavoritesfile
    # https://superuser.com/questions/421701/bash-reading-input-within-while-read-loop-doesnt-work
    while IFS= read -r -u 3 line; do
        # take the partial hostname from the line and append ".nordvpn.com". awk last field by "_"
        search_hostname=$(echo "$line" | awk -F'_' '{print $NF}').nordvpn.com
        # check if 'search_hostname' exists in the list of hostnames
        if grep -q -i "$search_hostname" <<<"$hostnames"; then
            # if the hostname exists, print a unicode checkmark
            echo -e "$line \u2705"
        else
            # if it doesn't exist, print a unicode "X" and prompt to delete
            echo
            echo -e "$line \u274c"
            read -n 1 -r -p "$(echo -e "${WColor}Delete${Color_Off}") $line from '$(basename "$nordfavoritesfile")'? (y/n): "
            echo
            if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                # delete the line using awk.  tried using 'sed -i' but had problems with special characters
                awk -v pattern="$line" '$0 != pattern' "$nordfavoritesfile" >favtemp && mv favtemp "$nordfavoritesfile"
                echo -e "$line ${WColor}deleted${Color_Off}"
                echo
            else
                echo -e "${EIColor}Keep${Color_Off} $line"
                echo
            fi
        fi
    done 3< <(sort < "$nordfavoritesfile")
    echo
    echo "Completed."
    echo
    echo
    # reload the favorites menu in case nordfavoritesfile has changed
    read -n 1 -s -r -p "Press any key to continue... "; echo
    favorites_menu
}
function allservers_update {
    # download an updated json file of all the nordvpn servers
    # if a backup file was created, compare it with the new json to see if any hostnames were added or removed
    #
    # backup the current json
    backup_file "$nordserversfile"
    #
    read -n 1 -r -p "Download an updated .json? (~20MB) (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl "https://api.nordvpn.com/v1/servers?limit=9999999" > "$nordserversfile"
        echo
        echo -e "Saved as: ${EColor}$nordserversfile${Color_Off}"
        echo "File Size: $( du -k "$nordserversfile" | cut -f1 ) KB"
        echo "Last Modified: $( date -r "$nordserversfile" )"
        echo "Server Count: $( jq length "$nordserversfile" )"
        echo
    fi
    if [[ -f "$backupfile" ]]; then
        #
        oldfile="$backupfile"
        newfile="$nordserversfile"
        #
        echo -e "Hostname changes in ${EColor}$newfile${Color_Off}"
        echo -e "Compared to ${FColor}$oldfile${Color_Off}"
        echo
        # Compare the "hostname" fields from both JSON files. Sorted by city name. ChatGPT 3.5
        # use 'sort -u' to remove duplicates, otherwise diff will mark a removed dupe record, even though there is a remaining record with the same hostname
        diff -u <(jq -r '.[] | "\(.hostname) (\(.locations[0].country.city.name))"' "$oldfile" | sort -u) <(jq -r '.[] | "\(.hostname) (\(.locations[0].country.city.name))"' "$newfile" | sort -u) | grep -E '^[+-]' | tail -n +3 | sed -e 's/^-/Removed: /' -e 's/^+/Added: /'
        echo
    fi
}
function virtual_check {
    # compare the json output of virtual locations with the existing nordvirtual array
    #
    # associative arrays for comparison
    declare -A nordv_map
    declare -A jsonv_map
    #
    readarray -t jsonvirtual < <( jq -r '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.name, .locations[0].country.city.name' "$nordserversfile" | tr ' ' '_' | sort -u )
    #
    for element in "${nordvirtual[@]}"; do
        nordv_map["$element"]=1
    done
    for element in "${jsonvirtual[@]}"; do
        jsonv_map["$element"]=1
    done
    #
    mismatch="false"
    for element in "${!nordv_map[@]}"; do
        if [[ -z "${jsonv_map[$element]}" ]]; then
            mismatch="true"
            echo -e "${DColor}$element${Color_Off} is in the ${H1Color}nordvirtual array${Color_Off} but not in the ${H2Color}json output${Color_Off}"
        fi
    done
    for element in "${!jsonv_map[@]}"; do
        if [[ -z "${nordv_map[$element]}" ]]; then
            mismatch="true"
            echo -e "${DColor}$element${Color_Off} is in the ${H2Color}json output${Color_Off} but not in the ${H1Color}nordvirtual array${Color_Off}"
        fi
    done
    echo
    if "$mismatch"; then
        echo -e "${WColor}** Virtual location mismatch **${Color_Off}"
        echo "Please update $(basename "$nordserversfile") and then the nordvirtual array."
    else
        echo -e "${EColor}Virtual locations match. \u2705${Color_Off}"
        echo "Countries and Cities listed in the nordvirtual array match the"
        echo "virtual locations listed in $(basename "$nordserversfile")."
    fi
    echo
}
function virtual_locations {
    heading "Virtual Locations" "txt"
    #
    echo -e "${H2Color}Virtual Country Locations${Color_Off}"
    jq '.[] | select(.specifications[] | .title == "Virtual Location") | .locations[].country.name' "$nordserversfile" | tr ' ' '_' | sort -u | tr '\n' ' '
    echo; echo
    echo "Virtual Country Locations = $( jq '.[] | select(.specifications[] | .title == "Virtual Location") | .locations[].country.name' "$nordserversfile" | sort -u | wc -l )"
    echo
    echo
    echo -e "${H2Color}Virtual City Locations${Color_Off}"
    jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.city.name' "$nordserversfile" | tr ' ' '_' | sort -u | tr '\n' ' '
    echo; echo
    echo "Virtual City Locations = $( jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.city.name' "$nordserversfile" | tr ' ' '_' | sort -u | wc -l )"
    echo
    echo
    echo -e "${H2Color}Virtual Country and City Locations${Color_Off}"
    jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.name, .locations[0].country.city.name' "$nordserversfile" | tr ' ' '_' | sort -u | tr '\n' ' '
    echo; echo
    echo -e "${FColor}Can use this list to update the 'nordvirtual' array (line $(grep -m1 -n "nordvirtual=(" "$0" | cut -f1 -d':'))${Color_Off}"
    echo
    echo "Virtual Country and City Locations = $( jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.name, .locations[0].country.city.name' "$nordserversfile" | sort -u | wc -l )"
    echo
    virtual_check
}
function allservers_group {
    # query the local json to list and count the servers in a specified group
    # $1 = exact group name - "Double VPN" "Onion Over VPN" "Obfuscated Servers" "P2P" "Dedicated IP"
    # $2 = "quotes" - keep the double quotes to use the list elsewhere
    #
    heading "Group: $1" "txt"
    if [[ "$2" == "quotes" ]]; then
        jq --arg group "$1" '.[] | select(.groups[].title == $group) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -k2
    else
        jq -r --arg group "$1" '.[] | select(.groups[].title == $group) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -k2
    fi
    servercount="$( jq -r --arg group "$1" '.[] | select(.groups[].title == $group) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -u | wc -l )"
    echo
    echo "Servers in Group '$1' = $servercount"
    echo
}
function allservers_technology {
    # query the local json to list and count the servers with a specific technology
    # $1 = exact technology name - "Socks 5" "IKEv2/IPSec" "HTTP Proxy (SSL)" "HTTP CyberSec Proxy (SSL)" "OpenVPN UDP" "OpenVPN TCP" "Wireguard"
    # $2 = "quotes" - keep the double quotes to use the list elsewhere
    #
    heading "Technology: $1" "txt"
    if [[ "$2" == "quotes" ]]; then
        jq --arg tech "$1" '.[] | select(.technologies[].name == $tech) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -k2
    else
        jq -r --arg tech "$1" '.[] | select(.technologies[].name == $tech) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -k2
    fi
    servercount="$( jq --arg tech "$1" '.[] | select(.technologies[].name == $tech) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -u | wc -l )"
    echo
    echo "$1 Servers = $servercount"
    echo
}
function allservers_menu {
    # credit to ChatGPT 3.5 for help with jq syntax.  https://chat.openai.com/
    heading "All VPN Servers"
    parent="Nord API"
    echo "Query a local .json of all the NordVPN servers."
    echo "Requires 'curl' and 'jq'"
    echo
    if [[ -f "$nordserversfile" ]]; then
        echo -e "File: ${EColor}$nordserversfile${Color_Off}"
    else
        echo -e "${WColor}$nordserversfile does not exist.${Color_Off}"
        echo
        read -n 1 -r -p "Download the .json? (~20MB) (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            touch "$nordserversfile"
            curl "https://api.nordvpn.com/v1/servers?limit=9999999" > "$nordserversfile"
            echo -e "Saved as: ${EColor}$nordserversfile${Color_Off}"
        else
            REPLY="$upmenu"
            parent_menu
        fi
    fi
    echo "Last Modified: $( date -r "$nordserversfile" )"
    echo "Server Count: $( jq length "$nordserversfile" )"
    echo
    PS3=$'\n''Choose an option: '
    COLUMNS="$menuwidth"
    submallvpn=( "List All Servers" "Server Count" "Double-VPN Servers" "Onion Servers" "SOCKS Servers" "Obfuscated Servers" "P2P Servers" "Dedicated-IP Servers" "IKEv2/IPSec" "HTTPS Proxy" "HTTPS CyberSec Proxy" "OpenVPN UDP" "OpenVPN TCP" "WireGuard" "Virtual Locations" "Search Country" "Search City" "Search Server" "Connect" "Update List" "Exit" )
    select avpn in "${submallvpn[@]}"
    do
        parent_menu
        case $avpn in
            "List All Servers")
                heading "All the VPN Servers" "txt"
                jq -r '.[].hostname' "$nordserversfile" | sort -V -u
                echo
                echo "All Servers = $( jq length "$nordserversfile" )"
                echo
                ;;
            "Server Count")
                heading "Servers in each Country" "txt"
                jq -r 'group_by(.locations[0].country.name) | map({country: .[0].locations[0].country.name, total: length}) | sort_by(.country) | .[] | "\(.country) \(.total)"' "$nordserversfile"
                echo
                heading "Servers in each City" "txt"
                jq -r 'group_by(.locations[0].country.name + " " + .locations[0].country.city.name) | map({country: .[0].locations[0].country.name, city: .[0].locations[0].country.city.name, total: length}) | sort_by(.country, .city) | .[] | "\(.country) \(.city) \(.total)"' "$nordserversfile"
                echo
                ;;
            "Double-VPN Servers")
                allservers_group "Double VPN"
                ;;
            "Onion Servers")
                allservers_group "Onion Over VPN"
                ;;
            "SOCKS Servers")
                allservers_technology "Socks 5" "quotes"
                echo "Proxy names and locations are available online:"
                echo -e "${EColor}https://support.nordvpn.com/hc/en-us/articles/20195967385745${Color_Off}"
                echo
                ;;
            "Obfuscated Servers")
                allservers_group "Obfuscated Servers"
                ;;
            "P2P Servers")
                allservers_group "P2P"
                ;;
            "Dedicated-IP Servers")
                allservers_group "Dedicated IP"
                ;;
            "IKEv2/IPSec")
                allservers_technology "IKEv2/IPSec"
                ;;
            "HTTPS Proxy")
                allservers_technology "HTTP Proxy (SSL)" "quotes"
                ;;
            "HTTPS CyberSec Proxy")
                allservers_technology "HTTP CyberSec Proxy (SSL)" "quotes"
                ;;
            "OpenVPN UDP")
                allservers_technology "OpenVPN UDP"
                ;;
            "OpenVPN TCP")
                allservers_technology "OpenVPN TCP"
                ;;
            "WireGuard")
                allservers_technology "Wireguard"
                ;;
            "Virtual Locations")
                virtual_locations
                ;;
            "Search Country")
                # search for any country name rather than use a 'select' menu based on the CLI output
                heading "Search by Country Name" "txt"
                echo "Return the server hostnames in a particular country."
                echo "Please use exact format, eg. 'United States'"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "Enter the country name: " searchcountry
                if [[ -z $searchcountry ]]; then
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                else
                    echo
                    #heading "Servers in $searchcountry sorted by City" "txt"
                    #jq -r --arg searchcountry "$searchcountry" '.[] | select(.locations[].country.name == $searchcountry) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -k2
                    #echo
                    heading "Servers in $searchcountry sorted by Hostname" "txt"
                    jq -r --arg searchcountry "$searchcountry" '.[] | select(.locations[].country.name == $searchcountry) | "\(.hostname) (\(.locations[0].country.city.name))"' "$nordserversfile" | sort -V -k1
                    echo
                    echo "$searchcountry Servers = $( jq -r --arg searchcountry "$searchcountry" '.[] | select(.locations[].country.name == $searchcountry) | .hostname' "$nordserversfile" | sort -u | wc -l )"
                    echo
                fi
                ;;
            "Search City")
                heading "Search by City Name" "txt"
                echo "Return the server hostnames in a particular city."
                echo "Please use exact format, eg. 'Los Angeles'"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "Enter the city name: " searchcity
                if [[ -z $searchcity ]]; then
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                else
                    echo
                    heading "Servers in $searchcity" "txt"
                    jq -r --arg searchcity "$searchcity" '.[] | select(.locations[].country.city.name == $searchcity) | .hostname' "$nordserversfile" | sort -V
                    echo
                    echo "$searchcity Servers = $( jq -r --arg searchcity "$searchcity" '.[] | select(.locations[].country.city.name == $searchcity) | .hostname' "$nordserversfile" | sort -u | wc -l )"
                    echo
                fi
                ;;
            "Search Server")
                heading "Search by Server Hostname" "txt"
                echo "The complete record for a particular server stored in:"
                echo -e "${EColor}$nordserversfile${Color_Off}"
                echo "For example 'us9723.nordvpn.com'"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "Enter the full server hostname: " searchserver
                if [[ -z $searchserver ]]; then
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                else
                    echo
                    heading "Record for $searchserver" "txt"
                    jq --arg searchserver "$searchserver" '.[] | select(.hostname == $searchserver)' "$nordserversfile"
                    echo
                fi
                ;;
            "Connect")
                host_connect
                ;;
            "Update List")
                parent="All Servers"
                heading "Update Server List" "txt" "alt"
                allservers_update
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submallvpn[@]}" "$parent"
                ;;
        esac
    done
}
function nordapi_countrycode {
    # find the country code to use as an api filter
    #
    parent="Nord API"
    create_list "country" "count"
    # needed for "invalid option" error
    countrylist+=( "Exit" )
    # add an asterisk to virtual countries and shorten country names (if enabled)
    country_names_modify
    virtual_note "${modcountrylist[@]}"
    PS3=$'\n''Choose a Country: '
    select xcountry in "${modcountrylist[@]}"
    do
        parent_menu
        if [[ "$xcountry" == "Exit" ]]; then
            main_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#modcountrylist[@]} )); then
            country_names_restore
            # replace underscores to match the format, use lowercase for case insensitive search
            modxcountry=$(echo "$xcountry" | tr '_' ' ' | tr '[:upper:]' '[:lower:]')
            #
            country_code=$(curl --silent "https://api.nordvpn.com/v1/servers/countries" | \
            jq --raw-output --arg country "$modxcountry" '.[] | select(.name | ascii_downcase == $country) | .id')
            #
            echo
            echo -e "${H1Color}$xcountry${Color_Off}  (API Country ID = $country_code)"
            echo
            return
        else
            invalid_option "${#modcountrylist[@]}" "$parent"
        fi
    done
}
function nordapi_top_city {
    # Top 15 Recommended by City
    # retrieve all the servers for one country by the country code, then search by city
    #
    heading "Top 15 Recommended by City" "txt"
    parent="Nord API"
    # get the country code and set $xcountry for create_list "city"
    nordapi_countrycode
    create_list "city" "count"
    # needed for "invalid option" error
    citylist+=( "Exit" )
    # mark virtual cities with an asterisk
    city_names_modify
    virtual_note "${modcitylist[@]}"
    PS3=$'\n''Choose a City: '
    # must use $xcity for city_names_restore
    select xcity in "${modcitylist[@]}"
    do
        parent_menu
        if [[ "$xcity" == "Exit" ]]; then
            main_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#modcitylist[@]} )); then
            city_names_restore
            heading "Top 15 Recommended in $xcity" "txt" "alt"
            # replace underscores to match the format, use lowercase for case insensitive search
            modxcity=$(echo "$xcity" | tr '_' ' ' | tr '[:upper:]' '[:lower:]')
            #
            curl --silent "https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=$country_code&limit=0" | \
            jq -r --arg city "$modxcity" '.[] | select(.locations[0].country.city.name | ascii_downcase == $city) | "\(.load) %load   \(.locations[0].country.city.name) \(.locations[0].country.name)   \(.hostname)"' | \
            sort -n | head -n 15
            #
            echo
            read -n 1 -s -r -p "Press any key to continue... "; echo
            nordapi_menu
        else
            invalid_option "${#modcitylist[@]}" "$parent"
        fi
    done
}
function nordapi_menu {
    # Commands copied and modified from:
    # https://sleeplessbeastie.eu/2019/02/18/how-to-use-public-nordvpn-api/
    heading "NordVPN  API"
    parent="Tools"
    echo "Query the NordVPN Public API.  Requires 'curl' and 'jq'"
    echo "Commands may take a few seconds to complete."
    echo "Rate-limiting may cause a stall or 'Parse' error."
    echo
    if [[ "$connected" == "connected" ]]; then
        echo -e "Connected to: ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    PS3=$'\n''Choose an option: '
    COLUMNS="$menuwidth"
    submapi=("Host Server Load" "Top 15 Recommended" "Top 15 By Country" "Top 15 By City" "Top 100 World" "All VPN Servers" "All Cities" "Change Host" "Connect" "Exit")
    select napi in "${submapi[@]}"
    do
        parent_menu
        case $napi in
            "Host Server Load")
                heading "Current $nordhost Load" "txt" "alt"
                server_load
                ;;
            "Top 15 Recommended")
                heading "Top 15 Recommended" "txt" "alt"
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations?limit=15" | \
                jq -r 'sort_by(.load) | limit(15;.[]) | "\(.load) %load   \(.locations[0].country.city.name) \(.locations[0].country.name)   \(.hostname)"'
                echo
                ;;
            "Top 15 By Country")
                heading "Top 15 Recommended by Country" "txt"
                # find the country code to use as an api filter
                nordapi_countrycode
                heading "Top 15 Recommended in $xcountry" "txt" "alt"
                #
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations?limit=15&filters\[country_id\]=$country_code" | \
                jq -r 'sort_by(.load) | limit(15;.[]) | "\(.load) %load   \(.locations[0].country.city.name) \(.locations[0].country.name)   \(.hostname)"'
                #
                echo
                read -n 1 -s -r -p "Press any key to continue... "; echo
                nordapi_menu
                ;;
            "Top 15 By City")
                nordapi_top_city
                ;;
            "Top 100 World")
                heading "Top 100 Recommended Servers Worldwide" "txt" "alt"
                #
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations?limit=0" | \
                jq -r '.[] | "\(.load) %load   \(.locations[0].country.city.name) \(.locations[0].country.name)   \(.hostname)"' | \
                sort -n | head -n 100
                #
                echo
                ;;
            "All VPN Servers")
                allservers_menu
                ;;
            "All Cities")
                city_count
                ;;
            "Change Host")
                change_host
                ;;
            "Connect")
                host_connect
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submapi[@]}" "$parent"
                ;;
        esac
    done
}
function change_host {
    heading "Change Host" "txt"
    echo "Change the Hostname for testing purposes."
    echo
    if [[ "$connected" == "connected" ]]; then
        echo -e "Connected to: ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    echo "Choose a new Hostname/IP for testing"
    read -r -p "'Enter' for default [$default_vpnhost]: " nordhost
    nordhost=${nordhost:-$default_vpnhost}
    echo
    echo -e "Now using ${LColor}$nordhost${Color_Off} for testing."
    echo "(Does not affect 'Rate VPN Server')"
    echo
}
function wireguard_ks {
    # Optional Linux iptables Kill Switch for WireGuard config files. (untested)
    # https://unix.stackexchange.com/questions/733430/does-wireguard-postup-predown-really-work-as-a-kill-switch
    # https://www.man7.org/linux/man-pages/man8/wg-quick.8.html
    # https://www.ivpn.net/knowledgebase/linux/linux-wireguard-kill-switch/
    # Allowlist LAN ip4 and ip6.  /u/sellibitze on reddit
    #   https://old.reddit.com/r/WireGuard/comments/ekdi8w/wireguard_kill_switch_blocks_connection_to_nas/fda0ikp/
    #
    echo
    read -n 1 -r -p "Add a Linux iptables Kill Switch? (untested) (y/n) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    #
cat << "EOF" >> "$wgfull"
PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PostUp = iptables -I OUTPUT -d 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT
PostUp = ip6tables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL ! -d fc00::/7 -j REJECT
PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PreDown = iptables -D OUTPUT -d 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT
PreDown = ip6tables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL ! -d fc00::/7 -j REJECT
EOF
    #
    fi
}
function wireguard_gen {
    # Based on Tomba's NordLynx2WireGuard script
    # https://github.com/TomBayne/tombas-script-repo
    heading "WireGuard"
    parent="Tools"
    echo "Generate a WireGuard config file from your currently active"
    echo "NordLynx connection.  Requires WireGuard/WireGuard-Tools."
    echo "Commands require sudo.  Optional iptables Kill Switch for use"
    echo "on Linux systems only.  Filenames limited to 15 characters."
    echo "Note: Keep your Private Key secure."
    echo
    set_vars
    # limit config file name to 15 characters excluding extension.  truncate city name if necessary.
    max_wgcity=$(( 15 - ${#server} - 1 ))   # calculate max length for city name.  minus 1 for underscore
    wgcity=$(echo "$city" | tr -d ' ' | cut -c 1-$max_wgcity)
    #
    wgconfig="${wgcity}_${server}.conf"     # Filename
    wgfull="${wgdir}/${wgconfig}"           # Full path and filename
    #
    if ! app_exists "wg"; then
        echo -e "${WColor}WireGuard-Tools could not be found.${Color_Off}"
        echo "Please install WireGuard and WireGuard-Tools."
        echo "eg. 'sudo apt install wireguard wireguard-tools'"
        echo
        return
    elif [[ "$connected" != "connected" ]] || [[ "$technology" != "nordlynx" ]]; then
        echo -e "The VPN is $connectedc."
        echo -e "The Technology is set to $technologydc."
        echo -e "${WColor}Must connect to your chosen server using NordLynx.${Color_Off}"
        echo
        return
    elif [[ -f "$wgfull" ]]; then
        echo -e "Current Server: ${EColor}$server.nordvpn.com${Color_Off}"
        echo
        echo -e "${WColor}$wgfull already exists${Color_Off}"
        echo
        openlink "$wgdir" "ask"
        return
    elif [[ "$meshnet" == "enabled" ]]; then
        echo -e "${WColor}Disable the Meshnet NordLynx interfaces and disconnect?${Color_Off}"
        echo "Please reconnect to your chosen server afterwards."
        echo
        change_setting "meshnet" "back"
        if [[ "$meshnet" == "disabled" ]]; then
            main_disconnect
        else
            return
        fi
    fi
    echo -e "Current Server: ${EColor}$server.nordvpn.com${Color_Off}"
    echo -e "${CIColor}$city ${COColor}$country ${IPColor}$ipaddr ${Color_Off}"
    echo
    echo "Generate WireGuard config file:"
    echo -e "${LColor}$wgfull${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        REPLY="$upmenu"
        parent_menu
    fi
    echo
    #
    address=$(ip route get 8.8.8.8 | cut -f7 -d' ' | tr -d '\n')
    #listenport=$(sudo wg showconf nordlynx | grep 'ListenPort = .*')
    privatekey=$(sudo wg showconf nordlynx | grep 'PrivateKey = .*')
    publickey=$(sudo wg showconf nordlynx | grep 'PublicKey = .*')
    endpoint=$(sudo wg showconf nordlynx | grep 'Endpoint = .*')
    #
    # shellcheck disable=SC2129 # individual redirects
    {
        echo "# $server.nordvpn.com $ipaddr" > "$wgfull"
        echo "# $city $country" >> "$wgfull"
        echo >> "$wgfull"
        echo "[Interface]" >> "$wgfull"
        echo "Address = ${address}/32" >> "$wgfull"
        echo "${privatekey}" >> "$wgfull"
        #
        echo "DNS = 103.86.96.100, 103.86.99.100" >> "$wgfull"  # Regular DNS
        # echo "DNS = 103.86.96.96, 103.86.99.99" >> "$wgfull"  # Threat Protection Lite DNS
        #
        wireguard_ks    # Prompt to add Linux iptables Kill Switch
        #
        echo >> "$wgfull"
        echo "[Peer]" >> "$wgfull"
        echo "${endpoint}" >> "$wgfull"
        echo "${publickey}" >> "$wgfull"
        echo "AllowedIPs = 0.0.0.0/0, ::/0" >> "$wgfull"
        echo "PersistentKeepalive = 25" >> "$wgfull"
    }
    #
    echo
    echo -e "${EColor}Completed \u2705${Color_Off}" # unicode checkmark
    echo
    echo -e "Saved as ${LColor}$wgfull${Color_Off}"
    echo
    if app_exists "highlight"; then
        highlight -O xterm256 "$wgfull"
    else
        cat "$wgfull"
    fi
    echo
    openlink "$wgfull" "ask"
    echo
}
function speedtest_ip {
    if [[ -z $iperfserver ]]; then
        heading "Set the Remote Server" "txt"
        echo "Enter the remote server IP address or hostname."
        echo
        read -r -p "iperf3 Server: " iperfserver
        echo
    fi
}
function speedtest_iperf3 {
    # $1 = parent menu name
    heading "iperf3"
    echo
    if [[ -n "$1" ]]; then
        parent="$1"
    else
        parent="Speed Test"
    fi
    echo "Test upload and download transfer speeds between devices."
    echo "Meshnet Peers, LAN Peers, Remote Peers, etc."
    echo "Start the server on one device, then run the tests from another."
    echo
    if ! app_exists "iperf3"; then
        echo -e "${WColor}iperf3 could not be found.${Color_Off}"
        echo "Please install iperf3.  https://iperf.fr/ "
        echo "eg. 'sudo apt install iperf3'"
        echo
        return
    fi
    PS3=$'\n''Select a test: '
    submiprf=( "Start a Server" "Set Remote Server" "Send & Receive" "Send" "Receive" "Ping Server" "Meshnet Peers" "Exit" )
    select iprf in "${submiprf[@]}"
    do
        parent_menu
        case $iprf in
            "Start a Server")
                heading "Start an iperf3 Server" "txt"
                echo -e "${FColor}(CTRL-C to quit)${Color_Off}"
                echo
                iperf3 -s
                echo
                ;;
            "Set Remote Server")
                iperfserver=""
                speedtest_ip
                ;;
            "Send & Receive")
                # see "iperf3 --help" for test options
                speedtest_ip
                heading "Send & Receive" "txt"
                echo -e "${ULColor}Send to $iperfserver${Color_Off}"
                echo
                iperf3 -c "$iperfserver"
                echo
                echo -e "${DLColor}Receive from $iperfserver${Color_Off}"
                echo
                iperf3 -c "$iperfserver" -R
                echo
                ;;
            "Send")
                speedtest_ip
                heading "Send" "txt"
                echo -e "${ULColor}Send to $iperfserver${Color_Off}"
                echo
                iperf3 -c "$iperfserver"
                echo
                ;;
            "Receive")
                speedtest_ip
                heading "Receive" "txt"
                echo -e "${DLColor}Receive from $iperfserver${Color_Off}"
                echo
                iperf3 -c "$iperfserver" -R
                echo
                ;;
            "Ping Server")
                speedtest_ip
                heading "Ping the iperf3 Server" "txt"
                ping_host "$iperfserver" "show"
                ;;
            "Meshnet Peers")
                heading "Meshnet Peers" "txt"
                echo "List all the Meshnet peers that are currently online."
                echo
                nordvpn meshnet peer list --filter online
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submiprf[@]}" "$parent"
                ;;
        esac
    done
}
function speedtest_menu {
    heading "SpeedTests"
    parent="Tools"
    echo
    main_logo "stats_only"
    echo "Perform download and upload tests using the speedtest-cli"
    echo "or iperf3.  Open links to run browser-based speed tests."
    echo
    if ! app_exists "speedtest-cli"; then
        echo -e "${WColor}speedtest-cli could not be found.${Color_Off}"
        echo "Please install speedtest-cli"
        echo "eg. 'sudo apt install speedtest-cli'"
        echo
    fi
    PS3=$'\n''Select a test: '
    COLUMNS="$menuwidth"
    submspeed=( "Download & Upload" "Download Only" "Upload Only" "Single DL" "Server List" "Latency & Load" "iperf3" "wget" "speedtest.net"  "speedof.me" "fast.com" "linode.com" "digitalocean.com" "nperf.com" "Exit" )
    select spd in "${submspeed[@]}"
    do
        parent_menu
        case $spd in
            "Download & Upload")
                echo
                speedtest-cli
                ;;
            "Download Only")
                echo
                speedtest-cli --no-upload
                ;;
            "Upload Only")
                echo
                speedtest-cli --no-download
                ;;
            "Single DL")
                echo
                speedtest-cli --single --no-upload
                ;;
            "Server List")
                heading "SpeedTest Servers" "txt"
                speedtest-cli --list
                echo
                echo "Enter the Server ID# to run a standard test."
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "Server ID: "
                if [[ -n $REPLY ]]; then
                    echo
                    echo -e "${LColor}speedtest-cli --server $REPLY${Color_Off}"
                    echo
                    speedtest-cli --server "$REPLY"
                    echo
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                ;;
            "Latency & Load")
                echo
                if [[ "$connected" != "connected" ]]; then
                    echo -e "(VPN $connectedc)"
                    read -r -p "Enter a Hostname/IP [Default $default_vpnhost]: " nordhost
                    nordhost=${nordhost:-$default_vpnhost}
                    echo
                    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
                    echo
                fi
                if [[ "$connected" == "connected" ]] && [[ "$technology" == "openvpn" ]]; then
                    echo -e "$technologydc - Server IP will not respond to ping."
                    echo "Attempt to ping your external IP instead."
                    echo
                    ipinfo_curl
                    if [[ -n "$extip" ]]; then
                        ping_host "$extip" "show"
                    fi
                else
                    ping_host "$nordhost" "show"
                fi
                server_load
                ;;
            "iperf3")
                speedtest_iperf3
                ;;
            "wget")
                wgetfile="https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso"
                #wgetfile="https://ash-speed.hetzner.com/1GB.bin"
                #
                heading "wget" "txt"
                echo -e "${H2Color}wget -O /dev/null '$wgetfile'${Color_Off}"
                echo
                read -n 1 -r -p "Proceed? (y/n) "; echo
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    speedtest_menu
                fi
                echo -e "${FColor}(CTRL-C to quit)${Color_Off}"
                echo
                wget -O /dev/null "$wgetfile"
                ;;
            "speedtest.net")    openlink "http://www.speedtest.net/";;
            "speedof.me")       openlink "https://speedof.me/";;
            "fast.com")         openlink "https://fast.com";;
            "linode.com")       openlink "https://www.linode.com/speed-test/";;
            "digitalocean.com") openlink "http://speedtest-blr1.digitalocean.com/";;
            "nperf.com")        openlink "https://www.nperf.com/en/";;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submspeed[@]}" "$parent"
                ;;
        esac
    done
}
function tools_menu {
    heading "Tools"
    parent="Main"
    if [[ "$connected" == "connected" ]]; then
        main_logo "stats_only"
        PS3=$'\n''Choose an option: '
    else
        echo -e "(VPN $connectedc)"
        read -r -p "Enter a Hostname/IP [Default $default_vpnhost]: " nordhost
        nordhost=${nordhost:-$default_vpnhost}
        echo
        echo -e "Hostname: ${LColor}$nordhost${Color_Off}"
        echo "(Does not affect 'Rate VPN Server')"
        echo
        PS3=$'\n''Choose an option (VPN Off): '
    fi
    COLUMNS="$menuwidth"
    submtools=( "NordVPN API" "Speed Tests" "WireGuard" "External IP" "Server Load" "Rate VPN Server" "Ping VPN Server" "Ping Test" "My TraceRoute" "Nord DNS Test" "ipleak cli" "ipleak.net" "dnsleaktest.com" "dnscheck.tools" "test-ipv6.com" "ipinfo.io" "iplocation.net" "ipregistry.co" "ip2location.io" "ipaddress.my" "locatejs.com" "browserleaks.com" "bash.ws" "Change Host" "World Map" "Outage Map" "Down Detector" "Exit" )
    select tool in "${submtools[@]}"
    do
        parent_menu
        case $tool in
            "NordVPN API")
                nordapi_menu
                ;;
            "Speed Tests")
                speedtest_menu
                ;;
            "WireGuard")
                wireguard_gen
                ;;
            "External IP")
                echo
                ipinfo_curl
                ;;
            "Server Load")
                echo
                server_load
                ;;
            "Rate VPN Server")
                echo
                rate_server
                ;;
            "Ping VPN Server")
                echo
                ping_host "$nordhost" "show"
                ;;
            "Ping Test")
                clear -x
                echo -e "${LColor}"
                echo "Ping Google DNS 8.8.8.8, 8.8.4.4"
                echo "Ping Cloudflare DNS 1.1.1.1, 1.0.0.1"
                echo "Ping Telstra Australia 139.130.4.4"
                echo -e "${FColor}"
                echo "(CTRL-C to quit)"
                echo -e "${Color_Off}"
                echo -e "${LColor}===== Google =====${Color_Off}"
                ping_host "8.8.8.8"; echo
                ping_host "8.8.4.4"; echo
                echo -e "${LColor}===== Cloudflare =====${Color_Off}"
                ping_host "1.1.1.1"; echo
                ping_host "1.0.0.1"; echo
                echo -e "${LColor}===== Telstra =====${Color_Off}"
                ping_host "139.130.4.4"; echo
                ;;
            "My TraceRoute")
                echo
                read -r -p "Destination [Default: $nordhost]: " target
                target=${target:-$nordhost}
                echo
                mtr "$target"
                ;;
            "Nord DNS Test")
                openlink "https://nordvpn.com/dns-leak-test/"
                ;;
            "ipleak cli")
                # https://airvpn.org/forums/topic/14737-api/
                # random 40-character string
                ipleak_session=$( head -1 <(fold -w 40  <(tr -dc 'a-zA-Z0-9' < /dev/urandom)) )
                echo
                if [[ "$connected" == "connected" ]]; then
                    echo -e "${LColor}VPN Server IP:${Color_Off} $ipaddr"
                    echo
                    if [[ "$customdns" != "disabled" ]]; then
                        echo -e "$dns Current $dns_servers"
                        echo
                    fi
                else
                    echo -e "(VPN $connectedc)"
                    echo
                fi
                echo -e "${EColor}ipleak.net DNS Detection: ${Color_Off}"
                echo -e "${Color_Off}$( timeout 10 curl --silent https://"$ipleak_session"-"$RANDOM".ipleak.net/dnsdetection/ | jq .ip )"
                echo
                ;;
            "ipleak.net")       openlink "https://ipleak.net/";;
            "dnsleaktest.com")  openlink "https://dnsleaktest.com/";;
            "dnscheck.tools")   openlink "https://dnscheck.tools/";;
            "test-ipv6.com")    openlink "https://test-ipv6.com/";;
            "ipinfo.io")        openlink "https://ipinfo.io/";;
            "iplocation.net")   openlink "https://www.iplocation.net/ip-lookup";;
            "ipregistry.co")    openlink "https://ipregistry.co/";;
            "ip2location.io")   openlink "https://www.ip2location.io/";;
            "ipaddress.my")     openlink "https://www.ipaddress.my/";;
            "locatejs.com")     openlink "https://locatejs.com/";;
            "browserleaks.com") openlink "https://browserleaks.com/";;
            "bash.ws")          openlink "https://bash.ws/";;
            "Change Host")
                change_host
                ;;
            "World Map")
                # may be possible to highlight location
                heading "OpenStreetMap ASCII World Map" "txt"
                echo "- arrow keys to navigate"
                echo "- 'a' and 'z' to zoom"
                echo "- 'q' to quit"
                echo
                read -n 1 -r -p "telnet mapscii.me ? (y/n) "; echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    telnet mapscii.me
                fi
                echo
                ;;
            "Outage Map")
                echo
                openlink "https://www.thousandeyes.com/outages/" "ask"
                ;;
            "Down Detector")
                echo
                openlink "https://downdetector.com/status/nord-vpn/" "ask"
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submtools[@]}" "$parent"
                ;;
        esac
    done
}
function set_defaults_ask {
    heading "Set Defaults: ${H2Color}Settings${H1Color}" "txt"
    parent="Settings"
    echo "Disconnect the VPN and apply the NordVPN settings"
    echo "specified in 'function set_defaults'"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_defaults
        heading "Set Defaults: ${H2Color}Allowlist${H1Color}" "txt"
        read -n 1 -r -p "Go to the Allowlist setting? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            allowlist_setting "back"
        fi
        heading "Set Defaults: ${H2Color}CustomDNS${H1Color}" "txt"
        read -n 1 -r -p "Go to the CustomDNS setting? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            set_vars
            customdns_menu
        fi
        main_menu
    fi
}
function script_info {
    # display the customization options from the top of the script
    echo
    echo "$0"
    echo
    startline=$(grep -m1 -n "Customization" "$0" | cut -f1 -d':')
    endline=$(grep -m1 -n "=End=" "$0" | cut -f1 -d':')
    numlines=$(( endline - startline + 2 ))
    if app_exists "highlight"; then
        highlight -l -O xterm256 "$0" | head -n "$endline" | tail -n "$numlines"
    else
        cat -n "$0" | head -n "$endline" | tail -n "$numlines"
    fi
    echo
    echo "Need to edit the script to change these settings."
    echo
    openlink "$0" "ask" "exit"
    settings_menu
}
function quick_connect {
    # This is an alternate method of connecting to the Nord recommended server.
    # In some cases it may be faster than using "nordvpn connect"
    # Requires 'curl' and 'jq'
    # Auguss82 via github
    heading "QuickConnect"
    echo
    if [[ "$connected" == "connected" ]] && [[ "$killswitch" == "disabled" ]]; then
        read -n 1 -r -p "Disconnect the VPN to find a nearby server? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            disconnect_vpn "force"
        fi
    fi
    if [[ "$connected" != "connected" ]] && [[ "$killswitch" == "enabled" ]]; then
        echo -e "The VPN is $connectedc with the Kill Switch $killswitchc"
        bestserver=""
    elif [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec"
        bestserver=""
    else
        echo -n "Getting the recommended server... "
        bestserver="$(timeout 10 curl --silent 'https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations' | jq --raw-output '.[0].hostname' | awk -F. '{print $1}')"
        echo
    fi
    echo
    if [[ -z $bestserver ]]; then
        echo -e "Request failed. Trying: '${LColor}nordvpn connect${Color_Off}'"
        echo
        nordvpn connect
    else
        echo -e "Connect to ${LColor}$bestserver${Color_Off}"
        echo
        nordvpn connect "$bestserver"
    fi
    status
    exit
}
function group_all_menu {
    # all available groups
    heading "All Groups"
    parent="Group"
    create_list "group"
    echo "Groups that are available with"
    echo
    echo -e "Technology: $technologydc"
    if [[ "$technology" == "openvpn" ]]; then
        echo -e "Obfuscate: $obfuscatec"
    fi
    echo
    PS3=$'\n''Connect to Group: '
    select xgroup in "${grouplist[@]}"
    do
        parent_menu
        if [[ "$xgroup" == "Exit" ]]; then
            main_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#grouplist[@]} )); then
            heading "$xgroup"
            disconnect_vpn
            echo "Connect to the $xgroup group."
            echo
            nordvpn connect --group "$xgroup"
            status
            exit
        else
            invalid_option "${#grouplist[@]}" "$parent"
        fi
    done
}
function favorites_menu {
    heading "Favorites"
    parent="Main"
    main_logo "stats_only"
    echo "Keep track of your favorite individual servers by adding them to"
    echo "this list. For example low ping servers or streaming servers."
    echo
    if [[ -f "$nordfavoritesfile" ]]; then
        # remove leading and trailing spaces and tabs, delete empty lines
        # prevent sed from changing the "Last Modified" file property unless it actually makes changes
        if ! cmp -s "$nordfavoritesfile" <( sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' -e '/^$/d' "$nordfavoritesfile" ); then
            sed -i -e 's/^[ \t]*//' -e 's/[ \t]*$//' -e '/^$/d' "$nordfavoritesfile"
        fi
    else
        echo -e "${WColor}$nordfavoritesfile does not exist.${Color_Off}"
        echo
        read -n 1 -r -p "Create the file? (y/n) "; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            touch "$nordfavoritesfile"
            favorites_menu
        else
            main_menu
        fi
    fi
    readarray -t favoritelist < <( sort < "$nordfavoritesfile" )
    if (( "${#favoritelist[@]}" > 1 )); then
        rfavorite=$( printf '%s\n' "${favoritelist[ RANDOM % ${#favoritelist[@]} ]}" )
        favoritelist+=( "Random" )
    fi
    if [[ "$connected" == "connected" ]]; then
        if grep -q -i "$server" "$nordfavoritesfile"; then
            echo -e "The Current Server is in the list:  ${FColor}$( grep -i "$server" "$nordfavoritesfile" )${Color_Off}"
            echo
        else
            favoritelist+=( "Add Current Server" )
        fi
    fi
    favoritelist+=( "Add Server" "Edit File" "Verify" "Exit" )
    PS3=$'\n''Connect to Server: '
    select xfavorite in "${favoritelist[@]}"
    do
        parent_menu
        case $xfavorite in
            "Exit")
                main_menu
                ;;
            "Verify")
                favorites_verify
                ;;
            "Edit File")
                heading "Edit File" "txt"
                echo "Add one server per line."
                echo
                echo -e "Format:  AnyName${H2Color}<underscore>${Color_Off}ActualServerNumber"
                echo "Examples:  Netflix_us8247  Gaming_ca1672"
                echo
                openlink "$nordfavoritesfile" "ask" "exit"
                favorites_menu
                ;;
            "Add Server")
                heading "Add Server" "txt"
                echo -e "Format:  AnyName${H2Color}<underscore>${Color_Off}ActualServerNumber"
                echo "Examples:  Netflix_us8247  Gaming_ca1672"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "Enter the full server name and number: "
                if [[ -n $REPLY ]]; then
                    echo "$REPLY" >> "$nordfavoritesfile"
                    echo
                    echo -e "Added ${FColor}$REPLY${Color_Off} to ${LColor}$nordfavoritesfile${Color_Off}"
                    echo
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                favorites_menu
                ;;
            "Add Current Server")
                favname="$(echo "$city" | tr -d ' _')_$server"
                #
                heading "Add $server to Favorites" "txt"
                echo -e "Format:  AnyName${H2Color}<underscore>${Color_Off}ActualServerNumber"
                echo "Examples:  Netflix_$server  Gaming_$server"
                echo -e "Note: The ${EColor}_$server${Color_Off} part will be added automatically."
                echo
                echo -e "Default: ${FColor}$favname${Color_Off}"
                echo
                echo -e "${FColor}(Hit 'Enter' for default or '$upmenu' to quit)${Color_Off}"
                echo
                read -r -p "Enter the server name: " favadd
                if [[ "$favadd" = "$upmenu" ]]; then
                    favorites_menu
                fi
                favadd=${favadd:-$favname}
                if [[ "$favadd" != *"$server"* ]]; then
                    favadd="${favadd}_${server}"
                fi
                echo "$favadd" >> "$nordfavoritesfile"
                echo
                echo -e "Added ${FColor}$favadd${Color_Off} to ${LColor}$nordfavoritesfile${Color_Off}"
                echo
                favorites_menu
                ;;
            "Random")
                heading "Random"
                disconnect_vpn
                echo "Connect to $rfavorite"
                echo
                nordvpn connect "$( echo "$rfavorite" | rev | cut -f1 -d'_' | rev )"
                status
                exit
                ;;
            *)
                if (( 1 <= REPLY )) && (( REPLY <= ${#favoritelist[@]} )); then
                    # to handle more than one <underscore> in the entry
                    # reverse the text so the first field is the server and the rest is heading
                    heading "$( echo "$xfavorite" | rev | cut -f2- -d'_' | rev )"
                    disconnect_vpn
                    echo "Connect to $xfavorite"
                    echo
                    nordvpn connect "$( echo "$xfavorite" | awk -F'_' '{print $NF}' )"
                    status
                    exit
                else
                    invalid_option "${#favoritelist[@]}" "$parent"
                fi
                ;;
        esac
    done
}
function group_menu {
    heading "Groups"
    parent="Main"
    echo
    PS3=$'\n''Choose a Group: '
    submgroups=("All_Groups" "Obfuscated" "Double-VPN" "Onion+VPN" "P2P" "Dedicated-IP" "Exit")
    select grp in "${submgroups[@]}"
    do
        parent_menu
        case $grp in
            "All_Groups")   group_all_menu;;
            "Obfuscated")   group_connect "Obfuscated_Servers";;
            "Double-VPN")   group_connect "Double_VPN";;
            "Onion+VPN")    group_connect "Onion_Over_VPN";;
            "P2P")          group_connect "P2P";;
            "Dedicated-IP") group_connect "Dedicated_IP";;
            "Exit")         main_menu;;
            *)              invalid_option "${#submgroups[@]}" "$parent";;
        esac
    done
}
function settings_menu {
    heading "Settings"
    parent="Main"
    echo
    indicators_display
    echo
    PS3=$'\n''Choose a Setting: '
    submsett=("Technology" "Protocol" "Firewall" "Routing" "Analytics" "KillSwitch" "TPLite" "Obfuscate" "Notify" "Tray" "AutoConnect" "IPv6" "Meshnet" "Custom-DNS" "LAN-Discovery" "Virtual" "Post-Quantum" "Allowlist" "Account" "Restart" "Reset" "IPTables" "Logs" "Script" "Defaults" "Exit")
    select sett in "${submsett[@]}"
    do
        parent_menu
        case $sett in
            "Technology")       technology_setting;;
            "Protocol")         protocol_setting;;
            "Firewall")         firewall_setting;;
            "Routing")          routing_setting;;
            "Analytics")        analytics_setting;;
            "KillSwitch")       killswitch_setting;;
            "TPLite")           tplite_setting;;
            "Obfuscate")        obfuscate_setting;;
            "Notify")           notify_setting;;
            "Tray")             tray_setting;;
            "AutoConnect")      autoconnect_setting;;
            "IPv6")             ipv6_setting;;
            "Meshnet")          meshnet_menu "Settings";;
            "Custom-DNS")       customdns_menu;;
            "LAN-Discovery")    landiscovery_setting;;
            "Virtual")          virtual_setting;;
            "Post-Quantum")     postquantum_setting;;
            "Allowlist")        allowlist_setting;;
            "Account")          account_menu;;
            "Restart")          restart_service;;
            "Reset")            reset_app;;
            "IPTables")         iptables_menu;;
            "Logs")             service_logs;;
            "Script")           script_info;;
            "Defaults")         set_defaults_ask;;
            "Exit")             main_menu;;
            *)                  invalid_option "${#submsett[@]}" "$parent";;
        esac
    done
}
function pause_vpn {
    # disconnect the VPN, pause for a chosen number of minutes, then reconnect to any location
    #
    pcity=$(echo "$city" | tr ' ' '_' )
    pcountry=$(echo "$country" | tr ' ' '_' )
    #
    heading "Disconnect, Pause, and Reconnect" "txt" "alt"
    echo -e "$connectedcl ${CIColor}$pcity ${COColor}$pcountry ${SVColor}$server${Color_Off}"
    echo
    echo "Reconnect to any City, Country, Server, or Group."
    echo; echo
    echo -e "Complete this command or hit 'Enter' for ${FColor}$pcity${Color_Off}"
    echo
    read -r -p "nordvpn connect " pwhere
    if [[ -z "$pwhere" ]]; then
        printf '\e[A\e[K'   # erase previous line
        echo  "nordvpn connect $pcity"
    fi
    pwhere=${pwhere:-$pcity}
    echo
    read -r -p "How many minutes? Hit 'Enter' for [$default_pause]: " pminutes
    pminutes=${pminutes:-$default_pause}
    # use 'bc' to handle decimal minute input
    pseconds=$( echo "scale=0; $pminutes * 60/1" | bc )
    #
    disconnect_vpn "force" "check_ks"
    reload_applet
    set_vars
    heading "Pause VPN"
    echo -e "$connectedcl @ $(date)"
    echo
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "${WColor}Note:${Color_Off} $ks the Kill Switch is $killswitchc."
        echo
    fi
    echo -e "${FColor}Please do not close this window.${Color_Off}"
    echo
    echo -e "Will connect to ${EColor}$pwhere${Color_Off} after ${EColor}$pminutes${Color_Off} minutes."
    echo
    countdown_timer "$pseconds"
    heading "Reconnect"
    echo
    echo "Connect to $pwhere"
    echo
    # shellcheck disable=SC2086 # word splitting eg. "--group P2P United_States"
    nordvpn connect $pwhere
    status
    exit
}
function main_header {
    # headings used for main_menu connections
    # $1 = "defaults" - force a disconnect and apply default settings
    #
    heading "$opt"
    if [[ "$1" == "defaults" ]]; then
        set_defaults
    else
        disconnect_vpn       # will only disconnect if $disconnect="y"
    fi
    echo "Connect to $opt"
    echo
}
function main_disconnect {
    # disconnect option from the main menu
    heading "Disconnect"
    echo
    if [[ "$connected" == "connected" ]] && ! "$meshrouting"; then
        if [[ "$rate_prompt" =~ ^[Yy]$ ]]; then
            rate_server
            echo
        fi
        if [[ "$pause_prompt" =~ ^[Yy]$ ]]; then
            read -n 1 -r -p "Pause the VPN? (y/n) "; echo
            if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                pause_vpn
            fi
        fi
    fi
    disconnect_vpn "force" "check_ks"
    status
    exit
}
function app_exists {
    # check if nordvpn and third party applications are installed
    # $1 = app to check.  use "start" to initialize the array
    #
    if [[ "$1" == "start" ]]; then
        # populate the nordlist_apps array and echo the results on script startup
        #
        applications=( "wg" "jq" "curl" "figlet" "lolcat" "iperf3" "nordvpn" "highlight" "speedtest-cli" )
        #
        echo -e "${LColor}App Check${Color_Off}"
        for app in "${applications[@]}"; do
            if command -v "$app" &> /dev/null; then
                nordlist_apps["$app"]="true"
                echo -e "${EIColor}Y${Color_Off} $app"
            else
                nordlist_apps["$app"]="false"
                echo -e "${DIColor}N${Color_Off} $app"
            fi
        done
    else
        # check the nordlist_apps array to confirm the program is available
        if [[ "${nordlist_apps[$1]}" == "true" ]]; then
            return 0    # success
        else
            return 1    # failure
        fi
    fi
}
function start {
    # commands to run when the script first starts
    set_colors
    echo
    if [[ -n $SSH_TTY ]]; then
        # Check if the script is being run in an ssh session
        echo -e "${FColor}(The script is running over SSH)${Color_Off}"
        echo
        usingssh="true"
    else
        usingssh="false"
    fi
    if (( BASH_VERSINFO < 4 )); then
        echo "Bash Version $BASH_VERSION"
        echo -e "${WColor}Bash v4.0 or higher is required.${Color_Off}"
        echo
        exit 1
    fi
    if [[ -n "$titlebartext" ]]; then
        # Change the terminal window titlebar text. Tested with gnome-terminal.
        if "$usingssh"; then
            echo -ne "\033]2;$titlebartext $USER@$HOSTNAME\007"
        else
            echo -ne "\033]2;$titlebartext\007"
        fi
    fi
    app_exists "start"
    echo
    if app_exists "nordvpn"; then
        nordvpn --version
        echo
    else
        echo -e "${WColor}The NordVPN Linux client could not be found.${Color_Off}"
        echo "https://nordvpn.com/download/"
        echo
        exit 1
    fi
    if ! systemctl is-active --quiet nordvpnd; then
        echo -e "${WColor}nordvpnd.service is not active${Color_Off}"
        echo -e "${EColor}Starting the service... ${Color_Off}"
        echo "sudo systemctl start nordvpnd.service"
        sudo systemctl start nordvpnd.service || exit
        echo
    fi
    #
    checklogin="n"
    if [[ "$checklogin" =~ ^[Yy]$ ]]; then
        # Check if you are logged in.  This will cause a delay every time the script starts.
        login_check
    fi
    #
    if nordvpn status | grep -i "update"; then
        # "A new version of NordVPN is available! Please update the application."
        clear -x
        echo
        echo -e "${WColor}** A NordVPN update is available **${Color_Off}"
        echo
        echo
        read -n 1 -s -r -p "Press any key for the menu... "; echo
        echo
    fi
    #
    main_menu "start"
    #
}
#
start
#
# =====================================================================
# =====================================================================
# Notes
# ======
#
# Bash-Sensors Applet for Cinnamon Desktop (Recommended)
#
#   Shows the NordVPN connection status in the panel and runs nordlist.sh when clicked.
#   Mint-Menu - "Applets" - Download tab - "Bash-Sensors" - Install - Manage tab - (+)Add to panel
#   https://cinnamon-spices.linuxmint.com/applets/view/231
#
#   To use the icons from https://github.com/ph202107/nordlist/tree/main/icons
#   Download the icons to your device and modify "PATH_TO_ICON" in the command below.
#   Green = Connected, Red = Disconnected.  Screenshot:  https://github.com/ph202107/nordlist/blob/main/screenshots
#       Title:  NordVPN
#       Refresh Interval:  15 seconds or choose
#       Shell:  bash
#       Command 1: blank
#       Two Line Mode:  Off
#       Dynamic Icon:  On
#       Static Icon or Command:
#           if [[ "$( nordvpn status | awk -F ': ' '/Status/{print tolower($2)}' )" == "connected" ]]; then echo "PATH_TO_ICON/nord.round.green.png"; else echo "PATH_TO_ICON/nord.round.red.png"; fi
#       Dynamic Tooltip:  On
#       Tooltip Command:
#           To show the connection status and city:
#               echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -i -E "Status|City"
#           To show the entire output of "nordvpn status":
#               echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -v -i -E "update|feature"
#       Command on Applet Click:
#           gnome-terminal -- bash -c "/PATH/TO/SCRIPT/nordlist.sh; exec bash"
#       Display Output:  Off
#       Command on Startup:  blank
#
#   To use unicode symbols
#   Green Checkmark = Connected, Red X = Disconnected
#   Alternate Symbols: https://unicode-table.com/en/sets/check/
#       Title:  NordVPN
#       Refresh Interval:  15 seconds or choose
#       Shell:  bash
#       Command 1:
#           if [[ "$( nordvpn status | awk -F ': ' '/Status/{print tolower($2)}' )" == "connected" ]]; then echo -e "\u2705"; else echo -e "\u274c"; fi
#       Two Line Mode:  Off
#       Dynamic Icon:  Off
#       Static Icon or Command: blank
#       Dynamic Tooltip:  On
#       Tooltip Command:
#           To show the connection status and city:
#               echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -i -E "Status|City"
#           To show the entire output of "nordvpn status":
#               echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -v -i -E "update|feature"
#       Command on Applet Click:
#           gnome-terminal -- bash -c "/PATH/TO/SCRIPT/nordlist.sh; exec bash"
#       Display Output:  Off
#       Command on Startup:  blank
#
#   Command to reload the Bash-Sensors applet:
#       dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'bash-sensors@pkkk' string:'APPLET'
#
# =====================================================================
#
# Add repository and install:
#   cd ~/Downloads
#   wget -nc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn-release/nordvpn-release_1.0.0_all.deb
#   sudo apt install ~/Downloads/nordvpn-release_1.0.0_all.deb
#   sudo apt update
#   sudo apt install nordvpn
#
# Alternate install method:
#   sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
#   or
#   sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh)
#
# To reinstall:
#   sudo apt autoremove --purge nordvpn*
#   delete: /var/lib/nordvpn
#   delete: /var/run/nordvpn
#   delete: /home/username/.config/nordvpn
#   May need to re-add repo
#   sudo apt update
#   sudo apt install nordvpn
#
# To downgrade:
#   sudo apt autoremove --purge nordvpn*
#   delete: /var/lib/nordvpn
#   delete: /var/run/nordvpn
#   delete: /home/username/.config/nordvpn
#   May need to re-add repo
#   sudo apt update
#   Show versions:
#       apt list -a nordvpn
#   Example:
#       sudo apt install nordvpn=3.15.1
#
# 'Whoops! /run/nordvpn/nordvpnd.sock not found.'
#   sudo systemctl start nordvpnd.service
#
# 'Permission denied accessing /run/nordvpn/nordvpnd.sock'
#   sudo usermod -aG nordvpn $USER
#   reboot
#
# Whoops! Connection failed. Please try again. If the problem persists, contact our customer support.
#   Change technology setting and retest.  NordLynx to OpenVPN or vice versa.
#
# Whoops! Connection failed. Please try again. If the problem persists, contact our customer support.
#   On Ubuntu 22.04 - Make a symbolic link - https://redd.it/ttlwuv
#       sudo ln -s /usr/bin/resolvectl /usr/bin/systemd-resolve
#
# After system crash or hard restart
# 'Whoops! Connection failed. Please try again. If problem persists, contact our customer support.'
#   sudo chattr -i -a /var/lib/nordvpn/data/.config.ovpn
#   sudo chmod ugo+w /var/lib/nordvpn/data/.config.ovpn
#
# "Whoops! Cannot reach System Daemon"
#   Check that the service is started
#       systemctl is-active nordvpnd
#       sudo systemctl start nordvpnd.service
#   Check logs for daemon errors and daemon shutdown
#       journalctl -u nordvpnd.service
#       journalctl -xe
#       On Error "can't find gateway" - check DNS settings
#
# GPG error: https//repo.nordvpn.com: The following signatures couldn't be verified
# because the public key is not available: NO_PUBKEY
#   sudo wget https://repo.nordvpn.com/gpg/nordvpn_public.asc -O - | sudo apt-key add -
#
# 'Your account has expired. Renew your subscription now to continue
#   enjoying the ultimate privacy and security with NordVPN.'
#   delete: /var/lib/nordvpn/data/settings.dat
#   delete: /home/username/.config/nordvpn/nordvpn.conf
#   nordvpn login
#
# OpenVPN config files
#   https://support.nordvpn.com/Connectivity/Linux/1061938702/How-to-connect-to-NordVPN-using-Linux-Network-Manager.htm
#   https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
#   https://nordvpn.com/servers/tools/
#   Obfuscated Server ovpn config files
#       https://support.nordvpn.com/Connectivity/macOS/1061815912/Manual-connection-setup-with-Tunnelblick-on-macOS.htm
#       https://downloads.nordcdn.com/configs/archives/servers/ovpn_xor.zip
#
# NordLynx stability issues
#   Install WireGuard + WireGuard-Tools
#       sudo apt install wireguard wireguard-tools
#   https://wiki.archlinux.org/title/NordVPN
#       > (NordVPN) unmentioned dependency on wireguard-tools
#
# Disable IPv6
#   https://support.nordvpn.com/Connectivity/Linux/1047409212/How-to-disable-IPv6-on-Linux.htm
#   https://forums.linuxmint.com/viewtopic.php?p=2387296#p2387296
#   Blocked by default:  https://nordvpn.com/blog/nordvpn-implements-ipv6-leak-protection
#   May 2022 - IPv6 capable servers:  us9591 us9592 uk1875 uk1876
#
