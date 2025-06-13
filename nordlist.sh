#!/bin/bash
#
# Tested with NordVPN Version 3.20.3 on Linux Mint 21.3
# June 12, 2025
#
# Unofficial bash script to use with the NordVPN Linux CLI.
# Tested on Linux Mint with gnome-terminal and Bash v5.
# Should work fine on Ubuntu but is not tested with other distros.
# Fully customizable. All menu options and locations can be changed.
# Includes a basic applet for the Cinnamon Desktop (optional).
# Screenshots: https://github.com/ph202107/nordlist/tree/main/screenshots
# This script was made for personal use, there is no affiliation with NordVPN.
#
# Suggestions and feedback are welcome!  Create a new issue here:
# https://github.com/ph202107/nordlist
#
# =====================================================================
# Instructions
# =============
#
# 1a) Use 'git' to clone the repo:
#       git clone https://github.com/ph202107/nordlist.git
#     Note: All user-generated files are by default saved to the same directory
#     as nordlist.sh.  eg. "nord_favorites.txt"
#     To store these files in a separate directory, configure the 'nordlistbase'
#     option or set the path for each file individually.
#
# 1b) To download or update manually, open a terminal and follow these steps to
#     create a 'nordlist' folder in the home directory and add it to your $PATH.
#     Change the directory as you prefer.
#       cd ~
#       wget -O ~/nordlist-main.zip https://github.com/ph202107/nordlist/archive/refs/heads/main.zip
#       unzip ~/nordlist-main.zip
#       mkdir -p ~/nordlist
#       # Overwrites existing nordlist files but preserves nord_favorites.txt, etc.
#       cp -r ~/nordlist-main/* ~/nordlist/
#       rm -rf ~/nordlist-main.zip ~/nordlist-main
#       chmod +x ~/nordlist/nordlist.sh
#
#       # Optional: Add the nordlist folder to $PATH to run the script from anywhere.
#       echo 'export PATH="$HOME/nordlist:$PATH"' >> ~/.bashrc
#       source ~/.bashrc
#
# 2) Install External Programs
#       sudo apt update
#       # To display ASCII, use NordVPN API functions, and process Virtual Locations:
#       sudo apt install figlet lolcat curl jq expect
#       # Optional utilities:
#       sudo apt install wireguard wireguard-tools speedtest-cli iperf3 highlight
#
# 3) Install or Update the Nordlist Applet (Optional)
#       Only for for the Cinnamon Desktop Environment.
#       The Nordlist Applet displays the current VPN connection status in the
#       panel (blue icon = connected, red icon = disconnected) and when clicked
#       it launches nordlist.sh in a new terminal window.
#       https://github.com/ph202107/nordlist/tree/main/screenshots
#
#       Uninstall the Applet:
#           Right-click on the Cinnamon panel and select "Applets".
#           Or on Linux Mint open the Mint-Menu and type "Applets".
#           Click the "Manage" tab and select "Nordlist Applet" (nordlist_tray@ph202107)
#           Click "Uninstall" (X) to delete the applet.
#           Restart Cinnamon (Ctrl-Alt-Esc) or (Alt-F2 "r" "Enter")
#
#       Install or Update the Applet:
#           # If there is an existing applet please uninstall it first (see above).
#           cp -r ~/nordlist/applet/nordlist_tray@ph202107 ~/.local/share/cinnamon/applets/
#           Right-click on the Cinnamon panel and select "Applets".
#           Click the "Manage" tab and select "Nordlist Applet" (nordlist_tray@ph202107)
#           Click "Add" (+) to add the applet to your panel.
#           Restart Cinnamon (Ctrl-Alt-Esc)
#
#       Configure the Applet
#           Right-click on the Nordlist Applet in the panel and choose "Configure"
#           Set your update interval and full path to nordlist.sh
#           Use the absolute path, eg. "/home/username/nordlist/nordlist.sh"
#           Restart Cinnamon (Ctrl-Alt-Esc)
#
# 4) Change the script behavior and appearance by configuring the options below.
#
# 5) Run the script by clicking the Nordlist Applet, or open a terminal and enter:
#       nordlist.sh   (Or "./nordlist.sh" from the directory if it's not in $PATH)
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
# Source your customized variables and functions from an external file.
# Preserves modifications after script updates. Requires advanced setup.
# Please refer to 'function external_source' for details.  "y" or "n"
externalsource="n"
#
# The default location to save user-generated files is the same directory
# as nordlist.sh. You can specify any path to store these files separately,
# or set the path for each file individually.
# eg. nordlistbase="/home/$USER/nordlist_files"
nordlistbase="$(dirname "${BASH_SOURCE[0]}")"
#
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
# Specify the exit hop to use for Double_VPN. (Optional)
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
dipwhere=""
#
# Specify your Auto-Connect location. (Optional)
# When obfuscate is enabled, the location must support obfuscation.
# Connect to any Country, City, Server, or Group. eg:
# acwhere="Australia" acwhere="Sydney" acwhere="au731" acwhere="P2P"
acwhere=""
#
# Specify your Custom-DNS servers with a description.
# Can specify up to three DNS IP addresses separated by a space.
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
# NordVPN servers (about 25MB). Avoids API server timeouts.  Create the
# list at:  Tools - NordVPN API - All VPN Servers
serversfile="$nordlistbase/nord_allservers.json"
#
# Specify the absolute path and filename to store a local list of your
# favorite NordVPN servers.  eg. Low ping servers or streaming servers.
# Create the list in: 'Favorites'
favoritesfile="$nordlistbase/nord_favorites.txt"
#
# Favorite servers are labelled as (Favorite) above the main menu.
# You can choose to display the favorite name instead. eg. For a favorite
# named "Gaming_ca1672" display (Gaming) instead of (Favorite). "y" or "n"
showfavname="n"
#
# Specify the absolute path and filename to save a copy of the
# nordvpnd.service logs.  Create the file in: Settings - Logs
nordlogfile="$nordlistbase/nord_logs.txt"
# Also display this number of lines from the tail of the log.
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
# Requires 'curl' 'jq' and the local 'serversfile' mentioned above.
exitload="n"
#
# Show your external IP address and geolocation when the script exits.
# Requires 'curl' and 'jq'.  Connects to ipinfo.io.  "y" or "n"
exitip="n"
#
# Reload the Nordlist Cinnamon applet when the script exits.
# This will change the icon color (for connection status) immediately.
# Only for the Cinnamon DE with the applet installed. "y" or "n"
exitappletvpn="n"
#
# Reload the "Network Manager" Cinnamon applet when the script exits.
# This removes duplicate "nordlynx" entries from the applet. "y" or "n"
exitappletnm="n"
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
fast_menu="n"
#
# Automatically change these settings without prompting:  Firewall,
# Routing, Analytics, KillSwitch, TPLite, Notify, Tray, AutoConnect,
# IPv6, LAN-Discovery, Virtual-Location, Post-Quantum
fast_setting="n"
#
# When choosing a country from the 'Countries' menu, immediately
# connect to that country instead of choosing a city.
fast_country="n"
#
# The 'F' indicator will display when any of these options are enabled:
allfast=( "$fast_menu" "$fast_setting" "$fast_country" )
#
# =====================================================================
# Visual Options
# ===============
#
# Change the text and indicator colors in "function set_colors"
# Change the main menu figlet ASCII style in "function ascii_custom"
# Change the figlet ASCII style for headings in "function heading"
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
# See "function main_menu" for a guide to customize the main menu.
# Configure the first ten main menu items to suit your needs.
#
# Enjoy!
#
# ==End================================================================
#
function allowlist_commands {
    # Add your allowlist configuration commands here.
    # Enter one command per line.
    # Disable lan-discovery when adding private subnets to allowlist.
    # allowlist_start (keep this line unchanged)
    #
    #setting_disable "lan-discovery"
    #nordvpn allowlist remove all
    #nordvpn allowlist add subnet 192.168.1.0/24
    #
    # allowlist_end (keep this line unchanged)
    echo
}
function set_defaults {
    echo -e "${LColor}Apply the default configuration.${Color_Off}"
    echo
    # Calling this function can be useful to change multiple settings
    # at once and get back to a typical configuration.
    # Note: The VPN will be disconnected
    #
    # Configure as needed and comment-out the line below.
    echo -e "${WColor}** Edit 'function set_defaults' to configure this feature **${Color_Off}"; echo; return
    #
    # For each setting uncomment one of the two choices (or neither).
    #
    setting_enable "firewall"           # enables the firewall
    #setting_disable "firewall"         # disables the firewall. also disables killswitch
    #
    setting_enable "killswitch"         # enables the kill switch. also enables firewall
    #setting_disable "killswitch"
    #
    # Required: Choose one of these options for Technology and Protocol
    techpro_set "NordLynx" "UDP"        # disables obfuscate
    #techpro_set "OpenVPN" "UDP"        # disables post-quantum
    #techpro_set "OpenVPN" "TCP"        # disables post-quantum
    #techpro_set "NordWhisper" "WT"     # disables obfuscate and post-quantum
    #
    #setting_enable "post-quantum"      # requires NordLynx, disables meshnet
    setting_disable "post-quantum"
    #
    setting_enable "routing"            # typically this setting should be enabled
    #setting_disable "routing"
    #
    setting_enable "analytics"
    #setting_disable "analytics"
    #
    #setting_enable "threatprotectionlite"  # disables Custom-DNS
    setting_disable "threatprotectionlite"
    #
    #setting_enable "obfuscate"             # requires OpenVPN
    setting_disable "obfuscate"
    #
    #setting_enable "notify"
    setting_disable "notify"
    #
    #setting_enable "tray"
    setting_disable "tray"
    #
    #setting_enable "ipv6"
    setting_disable "ipv6"
    #
    #setting_enable "meshnet"           # disables post-quantum
    #setting_disable "meshnet"
    #
    setting_enable "lan-discovery"      # will remove private subnets from allowlist
    #setting_disable "lan-discovery"
    #
    #setting_enable "virtual-location"
    setting_disable "virtual-location"
    #
    #setting_enable "autoconnect"       # will use location "$acwhere" if specified above
    setting_disable "autoconnect"
    #
    #setting_enable "dns"               # will use the "$default_dns" specified above.  disables threatprotectionlite
    setting_disable "dns"
    #
    #allowlist_commands                 # run your allowlist configuration commands
    #
}
function main_menu {
    if [[ "$1" == "start" ]]; then
        echo -e "${EIColor}Welcome to nordlist!${Color_Off}"
    elif [[ "$fast_menu" =~ ^[Yy]$ || "$REPLY" == "$upmenu" ]]; then
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
                exit_status
                break
                ;;
            "Seattle")
                main_header
                nordvpn connect Seattle
                exit_status
                break
                ;;
            "Chicago")
                main_header
                nordvpn connect Chicago
                exit_status
                break
                ;;
            "Denver")
                main_header
                nordvpn connect Denver
                exit_status
                break
                ;;
            "Atlanta")
                main_header
                nordvpn connect Atlanta
                exit_status
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
                exit_status
                break
                ;;
            "P2P-Canada")
                # force a disconnect and apply default settings
                main_header "defaults"
                nordvpn connect --group p2p Canada
                exit_status
                break
                ;;
            "Discord")
                # I use this entry to connect to a specific server which can help
                # avoid repeat authentication requests. It then opens a URL.
                # It may be useful for other sites or applications.
                # Example: NordVPN discord  https://discord.gg/83jsvGqpGk
                #
                spec_server="us8247"    # server or location
                spec_url="https://discord.gg/83jsvGqpGk"
                #
                main_header
                echo -e "Server: ${LColor}$spec_server${Color_Off}"
                echo -e "URL: ${FColor}$spec_url${Color_Off}"
                echo
                nordvpn connect "$spec_server"
                exit_status
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
                setting_menu
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
                exit_status
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
    #
    if ! app_exists "figlet" || ! app_exists "lolcat"; then
        ascii_static
        return
    fi
    #
    if [[ "$status" != "connected" ]]; then
        figlet -t -f "standard" "NordVPN"
        return
    fi
    # This ASCII is displayed above the main menu.  Any text or variable(s) can be used.
    # eg. "$city", "$country", "$transferd", "NordVPN", "$HOSTNAME", "$(date)", etc.
    #
    asciitext="$city"
    #
    if [[ "$meshrouting" == "true" ]]; then
        asciitext="Meshnet Routing"
    fi
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
}
function heading {
    # The text or ASCII that displays after a menu selection is made.
    # $1 = heading text
    # $2 = "txt" - use regular text instead of figlet
    # $3 = "alt" - use alternate color for regular text
    #
    clear -x
    if [[ "$2" == "txt" ]] || ! app_exists "figlet" || ! app_exists "lolcat"; then
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
    if [[ "$1" == "Countries" || "$1" == "Favorites" ]]; then
        return
    else
        COLUMNS="$menuwidth"
    fi
}
function main_logo {
    # The ascii and stats shown above the main_menu and on script exit.
    set_vars
    if [[ "$1" != "stats_only" ]]; then
        # Specify  ascii_static or ascii_custom on the line below.
        ascii_custom
    fi
    if [[ "$meshrouting" == "true" ]]; then
        echo -e "$statuscl ${SVColor}$nordhost${Color_Off} ${IPColor}$ipaddr${Color_Off}"
    else
        echo -e "$statuscl ${CIColor}$city${Color_Off} ${COColor}$country${Color_Off} ${SVColor}$server${Color_Off} ${IPColor}$ipaddr${Color_Off} $fav"
    fi
    indicators_display
    echo -e "$transferc ${UPColor}$uptime${Color_Off}"
    if [[ -n "$transferc" ]]; then echo; fi
}
function indicators_display {
    # The "nordvpn settings" enabled/disabled indicators shown on the main menu, settings menu
    # $1 = "short" - short list of indicators for group_connect, techpro_menu, obfuscate_setting
    #
    # Use any symbol to separate the indicators.  Set a color in function set_colors.
    #indsep=" "         # blank space
    #indsep="\u2758"    # unicode vertical line
    indsep="\u00B7"     # unicode middle-dot
    #
    if [[ "$1" == "short" ]]; then
        echo -n "Current settings: "
        indall=( "$techpro" "$fw" "$ks" "$ob" "$mn" "$pq" )
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
        White='\033[0;37m'
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
    TColor=${LGreen}        # Technology-Protocol text
    TIColor=${BPurple}      # Technology-Protocol indicator
    #
    WColor=${BRed}          # Warnings, errors, disconnects
    LColor=${LCyan}         # 'Changes' lists and key info text
    ASColor=${BBlue}        # Color for the ascii_static image
    H1Color=${LGreen}       # Non-figlet headings
    H2Color=${LCyan}        # Non-figlet headings alternate
    DNSColor=${LCyan}       # DNS IP addresses
    # main_logo
    CNColor=${LGreen}       # Connected status
    DNColor=${LRed}         # Disconnected status
    CIColor=${Color_Off}    # City name
    COColor=${Color_Off}    # Country name
    SVColor=${Color_Off}    # Server name
    IPColor=${Color_Off}    # IP address
    FVColor=${LCyan}        # Favorite|Dedicated|etc server label
    ISColor=${DGrey}        # Indicators separator
    DLColor=${Green}        # Download stat
    ULColor=${Yellow}       # Upload stat
    UPColor=${Cyan}         # Uptime stat
    #
}
#
# ==End Diff===========================================================
# =====================================================================
#
function set_vars {
    # Set variables with the values found in "nordvpn settings" and "nordvpn status".
    #
    allvars=(
        status servername nordhost server ipaddr country city transferd transferu uptime
        technology protocol firewall fwmark routing analytics killswitch tplite obfuscate notify
        tray autoconnect ipversion6 meshnet customdns dns_servers landiscovery virtual postquantum
    )
    # Reset all vars to ensure stale data is never used.
    declare -g "${allvars[@]/%/=}"
    #
    # Store info in arrays
    readarray -t nordstatus < <( nordvpn status )
    readarray -t nordsettings < <( nordvpn settings )
    nordsettings=( "${nordsettings[@],,}" )   # convert everything to lowercase
    #
    # "nordvpn status"
    # When disconnected, $status is the only variable from nordstatus.
    # When meshnet is enabled, the transfer stats will not be zeroed on VPN reconnect.
    # Using <colon><space> as delimiter.
    #
    for line in "${nordstatus[@]}"
    do
        lc_line="${line,,}"     # lowercase used for matching and individual vars
        #
        case "$lc_line" in
            *"status"*)
                status="${lc_line##*: }"    # status is lowercase
                ;;
            *"server"*)
                servername="${line##*: }"   # eg "United States #9992" incl. "Virtual"
                ;;
            *"hostname"*)
                nordhost="${lc_line##*: }"  # eg "us9992.nordvpn.com". lowercase
                server="${nordhost%%.*}"    # eg "us9992". lowercase
                ;;
            *"ip:"*)
                ipaddr="${line##*: }"
                ;;
            *"country"*)
                country="${line##*: }"
                ;;
            *"city"*)
                city="${line##*: }"
                ;;
            #*"technology"*)    technology2="${lc_line##*: }";;     # lowercase
            #*"protocol"*)      protocol2="${line##*: }"; protocol2="${protocol2^^}";;  # uppercase
            #*"quantum"*)       postquantum2="${lc_line##*: }";;    # lowercase
                #
            *"transfer"*)
                read -ra words <<< "$line"           # split line into an array
                transferd="${words[1]} ${words[2]}"  # fields 2,3 = download stat with units
                transferu="${words[4]} ${words[5]}"  # fields 5,6 = upload stat with units
                ;;
            *"uptime"*)
                uptime="$line"
                ;;
        esac
    done
    #
    # "nordvpn settings"  (all elements in nordsettings[@] are lowercase)
    # $protocol and $obfuscate are only listed when using OpenVPN
    # $postquantum is not listed when using OpenVPN
    # Using <colon><space> as delimiter.
    #
    for line in "${nordsettings[@]}"
    do
        case "$line" in
            *"technology"*)     technology="${line##*: }";;
            *"protocol"*)       protocol="${line##*: }"; protocol="${protocol^^}";; # uppercase
            *"firewall:"*)      firewall="${line##*: }";;
            *"firewall mark"*)  fwmark="${line##*: }";;
            *"routing"*)        routing="${line##*: }";;
            *"analytics"*)      analytics="${line##*: }";;
            *"kill"*)           killswitch="${line##*: }";;
            *"threat"*)         tplite="${line##*: }";;
            *"obfuscate"*)      obfuscate="${line##*: }";;
            *"notify"*)         notify="${line##*: }";;
            *"tray"*)           tray="${line##*: }";;
            *"auto"*)           autoconnect="${line##*: }";;
            *"ipv6"*)           ipversion6="${line##*: }";;
            *"meshnet"*)        meshnet="${line##*: }";;
            *"dns"*)
                customdns="${line##*: }"
                # customdns is either "disabled" or lists the DNS IPs
                if [[ "$customdns" != "disabled" ]]; then
                    customdns="enabled"
                    dns_servers="${line##*: }"
                fi
                ;;
            *"discover"*)       landiscovery="${line##*: }";;
            *"virtual"*)        virtual="${line##*: }";;
            *"quantum"*)        postquantum="${line##*: }";;
        esac
    done
    # default to "disabled" if not found
    obfuscate="${obfuscate:-disabled}"
    postquantum="${postquantum:-disabled}"
    #
    # handle allowlist separately
    allowlist=()
    allowlist_var="disabled"
    collect_lines="false"
    #
    for line in "${nordsettings[@]}"
    do
        if [[ "$line" == *"allowlist"* ]]; then
            # "allowlist" is only listed when the allowlist has entries
            allowlist_var="enabled"
            collect_lines="true"
        fi
        if [[ "$collect_lines" == "true" ]]; then
            allowlist+=( "$line" )
        fi
        # allowlist is the last item in "nordvpn settings"
        # customize as necessary if the "nordvpn settings" output changes in the future
        if [[ -z "$line" ]]; then
            break
        fi
    done
    #
    set_vars_status
    set_vars_fav
    set_vars_techpro
    set_vars_indicators
    #
}
function set_vars_status {
    # Set the connection status variables and colors
    #
    # main_logo connection status and transfer stats
    if [[ "$status" == "connected" ]]; then
        statusc="${CNColor}$status${Color_Off}"
        statuscl="${CNColor}${status^}${Color_Off}:"
        transferc="${DLColor}\u25bc $transferd ${ULColor} \u25b2 $transferu ${Color_Off}"
    else
        statusc="${DNColor}$status${Color_Off}"
        statuscl="${DNColor}${status^}${Color_Off}"
        transferc=""
    fi
    #
    # Meshnet Routing status
    meshrouting="false"
    if [[ "$status" == "connected" && "$meshnet" == "enabled" && "$nordhost" != *"nordvpn.com"* ]]; then
        meshrouting="true"
    fi
}
function set_vars_fav {
    # Set the main_logo server label
    # Dedicated|Favorite|Obfuscated|Onion|Double|Virtual
    #
    fav=""
    if [[ "$status" != "connected" ]]; then
        return
    fi
    # Dedicated
    if [[ "$server" == "${dipwhere,,}" ]]; then
        fav="${FVColor}(Dedicated)${Color_Off}"
        return
    fi
    # Favorite
    # the favoritelist array is populated in 'function start' if the file exists
    # check if favoritelist exists and is not empty
    if [[ -v favoritelist && ${#favoritelist[@]} -gt 0 ]]; then
        for favorite in "${favoritelist[@]}"; do
            # server number after the last underscore
            favserver="${favorite##*_}"
            if [[ "${favserver,,}" == "$server" ]]; then
                if [[ "$showfavname" =~ ^[Yy]$ ]]; then
                    # server name before the last underscore
                    fav="${FVColor}(${favorite%_*})${Color_Off}"
                else
                    fav="${FVColor}(Favorite)${Color_Off}"
                fi
                return
            fi
        done
    fi
    # Obfuscated
    if [[ "$obfuscate" == "enabled" ]]; then
        fav="${FVColor}(Obfuscated)${Color_Off}"
        return
    fi
    # Onion or Double
    if [[ "$server" == *"-"* && "$meshrouting" == "false" ]]; then
        if [[ "$server" == *"onion"* ]]; then
            fav="${FVColor}(Onion)${Color_Off}"
        else
            fav="${FVColor}(Double)${Color_Off}"
        fi
        return
    fi
    # Virtual
    if [[ "${servername,,}" == *"virtual"* ]]; then
        fav="${FVColor}(Virtual)${Color_Off}"
        return
    fi
}
function set_vars_techpro {
    # The technology and protocol to display
    #
    # nordsettings = $technology - all technologies are listed
    # nordsettings = $protocol - only OpenVPN protocols are listed
    # nordstatus = $protocol2 (uncomment) - all protocols are listed but only while connected
    #
    case "$technology" in
        "openvpn")
            technologyd="OpenVPN"
            protocold="$protocol"
            ;;
        "nordlynx")
            # NordLynx protocol is always "UDP"
            technologyd="NordLynx"
            protocold="UDP"
            ;;
        "nordwhisper")
            # NordWhisper protocol is always "WebTunnel", use "WT"
            technologyd="NordWhisper"
            protocold="WT"
            ;;
    esac
    #
    # technology-protocol indicator
    techpro="${TIColor}${technologyd}\u00B7${protocold}${Color_Off}"
    #
}
function set_vars_indicators {
    # Set the indicator colors
    #
    # create an associative array of the indicators with the current
    # status of the corresponding enabled/disabled variables
    declare -gA nordlist_indicators=(
    #   ["$indkey"]="$indstatus"
        ["fw"]="$firewall"
        ["rt"]="$routing"
        ["an"]="$analytics"
        ["ks"]="$killswitch"
        ["tp"]="$tplite"
        ["ob"]="$obfuscate"
        ["no"]="$notify"
        ["tr"]="$tray"
        ["ac"]="$autoconnect"
        ["ip6"]="$ipversion6"
        ["mn"]="$meshnet"
        ["dns"]="$customdns"
        ["ld"]="$landiscovery"
        ["vl"]="$virtual"
        ["pq"]="$postquantum"
        ["al"]="$allowlist_var"
    )
    #
    for indkey in "${!nordlist_indicators[@]}"
    do
        indstatus="${nordlist_indicators[$indkey]}"
        #
        if [[ "$indstatus" == "enabled" ]]; then
            tmpcolor="${EColor}"
            tmpicolor="${EIColor}"
        else
            tmpcolor="${DColor}"
            tmpicolor="${DIColor}"
        fi
        #
        case "$indkey" in
            "ob")   obfuscatec="${tmpcolor}$indstatus${Color_Off}";;
            "mn")   meshnetc="${tmpcolor}$indstatus${Color_Off}";;
            "pq")   postquantumc="${tmpcolor}$indstatus${Color_Off}";;
        esac
        #
        declare -g "$indkey=${tmpicolor}${indkey^^}${Color_Off}"
        #
    done
    #
    # 'F' indicator
    fst=""
    if [[ ${allfast[*]} =~ [Yy] ]]; then
        fst="${FIColor}F${Color_Off}"
    fi
    #
    # 'SSH' indicator
    sshi=""
    if [[ "$usingssh" == "true" ]]; then
        sshi="${FIColor}SSH${Color_Off}"
    fi
    #
}
#
# =====================================================================
#
function techpro_set {
    # Set the technology and protocol.
    # arguments are case insensitive. $1 and $2 may be echoed
    # $1 = technology - "NordLynx" "OpenVPN" "NordWhisper"
    # $2 = protocol - "TCP" "UDP" "WT"
    #
    disconnect_vpn "force"
    #
    case "${1,,}" in
        "nordlynx")
            setting_disable "obfuscate"
            ;;
        "openvpn")
            setting_disable "post-quantum"
            ;;
        "nordwhisper")
            setting_disable "obfuscate"
            setting_disable "post-quantum"
            ;;
    esac
    #
    if [[ "$technology" == "${1,,}" ]]; then
        echo -e "${TColor}Technology is ${TIColor}$technologyd${Color_Off}"
    else
        echo -e "${TColor}Set Technology to ${TIColor}$1${Color_Off}"
        echo
        nordvpn set technology "$1"
        set_vars
    fi
    echo
    #
    # use $protocold for comparison since VPN is disconnected
    if [[ "${protocold,,}" == "${2,,}" ]]; then
        echo -ne "${TColor}Protocol is ${TIColor}$protocold${Color_Off}"
        if [[ "$technology" == "nordwhisper" ]]; then
            echo -ne "${TIColor} (WebTunnel)${Color_Off}"
        fi
        echo
    else
        echo -e "${TColor}Set Protocol to ${TIColor}$2${Color_Off}"
        echo
        nordvpn set protocol "$2"
        set_vars
    fi
    echo
}
function techpro_menu {
    # Choose a technology and protocol combination
    # $1 = "back" - skip the heading, return
    # $2 = "ovpn" - list only the OpenVPN options
    # $2 = "xnw" - list all the options but exclude NordWhisper
    #
    if [[ "$1" != "back" ]]; then
        parent="Settings"
        heading "Tech + Protocol"
        echo "NordLynx is based on WireGuard and may be faster with less overhead."
        echo "NordLynx is required to use Post-Quantum VPN and is UDP only."
        echo
        echo "OpenVPN is a standard VPN technology which can use TCP or UDP."
        echo "OpenVPN is required when using Obfuscated-Servers."
        echo
        echo "NordWhisper may be slower and is designed for use only on restricted"
        echo "networks where VPN traffic is blocked but web browsing is allowed."
        echo
        echo "The UDP protocol is mainly used for online streaming and downloading."
        echo "The TCP protocol is more reliable but usually slower than UDP."
        echo "WebTunnel (WT) mimics HTTPS web traffic to evade network censorship."
        echo
        disconnect_warning
    fi
    indicators_display "short"
    echo
    PS3=$'\n''Choose a Technology-Protocol: '
    COLUMNS="$menuwidth"
    #
    case "$2" in
        "ovpn") submtech=( "OpenVPN-UDP" "OpenVPN-TCP" );;
        "xnw")  submtech=( "NordLynx-UDP" "OpenVPN-UDP" "OpenVPN-TCP" );;
        *)      submtech=( "NordLynx-UDP" "OpenVPN-UDP" "OpenVPN-TCP" "NordWhisper-WT" );;
    esac
    if [[ "$1" != "back" ]]; then
        submtech+=( "Exit" )
    fi
    #
    select xtech in "${submtech[@]}"
    do
        parent_menu "$1"
        echo
        case $xtech in
            "NordLynx-UDP")
                techpro_set "NordLynx" "UDP"
                setting_change "post-quantum" "back"
                break
                ;;
            "OpenVPN-UDP")
                techpro_set "OpenVPN" "UDP"
                break
                ;;
            "OpenVPN-TCP")
                techpro_set "OpenVPN" "TCP"
                break
                ;;
            "NordWhisper-WT")
                techpro_set "NordWhisper" "WT"
                break
                ;;
            "Exit")
                main_menu
                ;;
            *)
                if [[ "$1" != "back" ]]; then
                    invalid_option "${#submtech[@]}" "$parent"
                fi
                ;;
        esac
    done
    #
    if [[ "$1" == "back" ]]; then
        return
    fi
    #
    main_menu
}
#
# =====================================================================
#
function setting_getvars {
    # Set the variable values for each Nord command
    # $1 = Nord command
    #
    chgloc=""
    case "$1" in
        "firewall")             chgname="the Firewall"; chgvar="$firewall"; chgind="$fw";;
        "routing")              chgname="Routing"; chgvar="$routing"; chgind="$rt";;
        "analytics")            chgname="Analytics"; chgvar="$analytics"; chgind="$an";;
        "killswitch")           chgname="the Kill Switch"; chgvar="$killswitch"; chgind="$ks";;
        "threatprotectionlite") chgname="Threat Protection Lite"; chgvar="$tplite"; chgind="$tp";;
        "obfuscate")            chgname="Obfuscate"; chgvar="$obfuscate"; chgind="$ob";;
        "notify")               chgname="Notify"; chgvar="$notify"; chgind="$no";;
        "tray")                 chgname="the Tray"; chgvar="$tray"; chgind="$tr";;
        "autoconnect")          chgname="Auto-Connect"; chgvar="$autoconnect"; chgind="$ac"; chgloc="$acwhere";;
        "ipv6")                 chgname="IPv6"; chgvar="$ipversion6"; chgind="$ip6";;
        "meshnet")              chgname="Meshnet"; chgvar="$meshnet"; chgind="$mn";;
        "dns")                  chgname="Custom-DNS"; chgvar="$customdns"; chgind="$dns"; chgloc="$default_dns";;
        "lan-discovery")        chgname="LAN-Discovery"; chgvar="$landiscovery"; chgind="$ld";;
        "virtual-location")     chgname="Virtual-Location"; chgvar="$virtual"; chgind="$vl";;
        "post-quantum")         chgname="Post-Quantum VPN"; chgvar="$postquantum"; chgind="$pq";;
        *)                      echo; echo -e "${WColor}'$1' not defined${Color_Off}"; echo; return;;
    esac
    #
}
function setting_change {
    # Prompt to enable or disable the NordVPN setting
    # $1 = Nord command
    # $2 = "back" - ignore fast_setting, return
    #
    if [[ "$2" != "back" ]]; then
        parent="Settings"
    fi
    #
    setting_getvars "$1"
    #
    if [[ "$chgvar" == "enabled" ]]; then
        chgvarc="${EColor}$chgvar${Color_Off}"
        chgprompt=$(echo -e "${DColor}Disable${Color_Off} $chgname? (y/n) ")
    else
        chgvarc="${DColor}$chgvar${Color_Off}"
        chgprompt=$(echo -e "${EColor}Enable${Color_Off} $chgname? (y/n) ")
    fi
    #
    echo -e "$chgind $chgname is $chgvarc."
    echo
    #
    if [[ "$fast_setting" =~ ^[Yy]$ && "$2" != "back" && "$1" != "obfuscate" ]]; then
        echo -e "${FColor}fast_setting is enabled.  Changing the setting.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "$chgprompt"; echo
    fi
    echo
    parent_menu "$2"
    #
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$chgvar" == "disabled" ]]; then
            setting_enable "$1"
        else
            setting_disable "$1"
        fi
    else
        echo -e "$chgind Keep $chgname $chgvarc."
        echo
    fi
    #
    if [[ "$2" == "back" ]]; then
        return
    fi
    #
    main_menu
}
function setting_enable {
    # Enable the NordVPN setting
    # $1 = Nord command
    # $2 = "showstatus" - show the status if already enabled
    # $2 = (when $1 = 'dns') - up to three DNS IPs separated by spaces
    #
    # after calling 'setting_change/enable/disable' from here, run this command again since
    # common variable values will have changed.  eg "$chgname" "$chgloc"
    setting_getvars "$1"
    #
    if [[ "$chgvar" == "enabled" && "$1" != "dns" ]]; then
        if [[ "$2" == "showstatus" ]]; then
            echo -e "$chgind $chgname is ${EColor}$chgvar${Color_Off}."
            echo
        fi
        return
    fi
    #
    case "$1" in
        "killswitch")
            setting_enable "firewall"
            setting_getvars "$1"
            ;;
        "threatprotectionlite")
            setting_disable "dns"
            setting_getvars "$1"
            ;;
        "autoconnect")
            if [[ -n $chgloc ]]; then
                echo -e "$chgname to ${LColor}$chgloc${Color_Off}"
                echo
            fi
            ;;
        "meshnet")
            setting_disable "post-quantum"
            setting_getvars "$1"
            echo -e "${WColor}Wait 30s to refresh the peer list.${Color_Off}"
            echo "Try disconnecting the VPN if $chgname fails to enable."
            echo
            ;;
        "dns")
            setting_disable "threatprotectionlite"
            setting_getvars "$1"
            #
            if [[ -n "$2" ]]; then
                echo -e "${EColor}Enable${Color_Off} $chgname ${DNSColor}$2${Color_Off}"
                echo
                # shellcheck disable=SC2086 # word splitting eg. "1.1.1.1 1.0.0.1"
                nordvpn set "$1" $2
                #
            else
                echo -e "${EColor}Enable${Color_Off} $chgname ${FColor}$dnsdesc${Color_Off} ${DNSColor}$default_dns${Color_Off}"
                echo
                # shellcheck disable=SC2086 # word splitting eg. "1.1.1.1 1.0.0.1"
                nordvpn set "$1" $default_dns
                #
            fi
            echo
            # update variables after any setting change
            set_vars
            # 'dns' does not use 'nordvpn set "$1" enabled'
            return
            ;;
        "post-quantum")
            setting_disable "meshnet"
            setting_getvars "$1"
            ;;
    esac
    #
    if [[ -n $chgloc ]]; then
        nordvpn set "$1" enabled "$chgloc"
    else
        nordvpn set "$1" enabled
    fi
    echo
    #
    # update variables after any setting change
    set_vars
    #
}
function setting_disable {
    # Disable the NordVPN setting
    # $1 = Nord command
    # $2 = "showstatus" - show the status if already disabled
    #
    setting_getvars "$1"
    #
    if [[ "$chgvar" == "disabled" ]]; then
        if [[ "$2" == "showstatus" ]]; then
            echo -e "$chgind $chgname is ${DColor}$chgvar${Color_Off}."
            echo
        fi
        return
    fi
    #
    case "$1" in
        "firewall")
            setting_disable "killswitch"
            setting_getvars "$1"
            ;;
        "routing")
            echo -e "${WColor}Disabling all traffic routing.${Color_Off}"
            echo
            ;;
        "dns")
            echo -e "${DColor}Disable${Color_Off} $chgname ${DNSColor}$dns_servers${Color_Off}"
            echo
            ;;
    esac
    #
    nordvpn set "$1" disabled
    echo
    #
    # update variables after any setting change
    set_vars
    #
}
function setting_menu {
    heading "Settings"
    parent="Main"
    echo
    indicators_display
    echo
    PS3=$'\n''Choose a Setting: '
    submsett=("Technology" "Protocol" "Firewall" "Routing" "Analytics" "KillSwitch" "TPLite" "Obfuscate" "Notify" "Tray" "AutoConnect" "IPv6" "Meshnet" "Custom-DNS" "LAN-Discovery" "Virtual-Loc" "Post-Quantum" "Allowlist" "Account" "Restart" "Reset" "IPTables" "Logs" "Script" "Defaults" "Exit")
    select sett in "${submsett[@]}"
    do
        parent_menu
        case $sett in
            "Technology")       techpro_menu;;
            "Protocol")         techpro_menu;;
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
            "Virtual-Loc")      virtual_setting;;
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
#
# =====================================================================
#
function firewall_setting {
    heading "Firewall"
    echo "Enable or Disable the NordVPN Firewall."
    echo "Enabling the Nord Firewall disables the Linux UFW."
    echo "The Firewall must be enabled to use the Kill Switch."
    echo
    echo -e "Firewall Mark: ${LColor}$fwmark${Color_Off}"
    echo "Change with: nordvpn set fwmark <mark>"
    echo
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "$ks - ${WColor}Note:${Color_Off} Disabling the Firewall also disables the Kill Switch."
        echo
    fi
    setting_change "firewall"
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
    setting_change "routing"
}
function analytics_setting {
    heading "Analytics"
    echo
    echo "Help NordVPN improve by sending anonymous aggregate data: "
    echo "crash reports, OS version, marketing performance, and "
    echo "feature usage data. (Nothing that could identify you.)"
    echo
    setting_change "analytics"
}
function killswitch_setting {
    heading "Kill Switch"
    echo "Kill Switch is a feature helping you prevent unprotected access to"
    echo "the internet when your traffic doesn't go through a NordVPN server."
    echo
    echo "When the Kill Switch is enabled and the VPN is disconnected, your"
    echo "computer should not be able to access the internet."
    echo
    if [[ "$status" != "connected" ]]; then
        echo -e "The VPN is currently $statusc."
        echo
    fi
    if [[ "$firewall" == "disabled" ]]; then
        echo -e "$fw - ${WColor}Note:${Color_Off} Enabling the Kill Switch also enables the Firewall."
        echo
    fi
    setting_change "killswitch"
}
function tplite_setting {
    heading "TPLite"
    echo "Threat Protection Lite is a feature protecting you from ads, unsafe"
    echo "connections, and malicious sites. Previously known as CyberSec."
    echo "Uses the Nord Threat Protection Lite DNS 103.86.96.96 103.86.99.99"
    echo
    if [[ "$customdns" == "enabled" ]]; then
        echo -e "$dns - ${WColor}Note:${Color_Off} Enabling TPLite disables Custom-DNS."
        echo -e "Current DNS: ${DNSColor}$dns_servers${Color_Off}"
        echo
    fi
    setting_change "threatprotectionlite"
}
function obfuscate_setting {
    # requires OpenVPN
    # must disconnect/reconnect to change setting
    heading "Obfuscate"
    parent="Settings"
    echo "Obfuscated servers can bypass restrictions such as network firewalls."
    echo "They are recommended for countries with restricted access. "
    echo
    echo "Only certain NordVPN locations support obfuscation.  Recommend connecting"
    echo "to the 'Obfuscated' group or through 'Countries' when Obfuscate is enabled."
    echo "Attempting to connect to unsupported locations will cause an error."
    echo
    disconnect_warning
    if [[ "$technology" != "openvpn" ]]; then
        indicators_display "short"
        echo -e "${WColor}Note:${Color_Off} Enabling Obfuscate will change the Technology to OpenVPN."
        echo
    fi
    echo -e "$ob Obfuscate is $obfuscatec."
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        read -n 1 -r -p "$(echo -e "${DColor}Disable${Color_Off} Obfuscate? (y/n) ")"; echo
    else
        read -n 1 -r -p "$(echo -e "${EColor}Enable${Color_Off} Obfuscate? (y/n) ")"; echo
    fi
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        if [[ "$obfuscate" == "enabled" ]]; then
            setting_disable "obfuscate"
            techpro_menu "back"
        else
            techpro_menu "back" "ovpn"
            setting_enable "obfuscate"
        fi
    else
        echo -e "$ob Keep Obfuscate $obfuscatec."
    fi
    main_menu
}
function notify_setting {
    heading "Notify"
    echo
    echo "Send OS notifications when the VPN status changes, and"
    echo "on Meshnet file transfer events."
    echo
    setting_change "notify"
}
function tray_setting {
    heading "Tray"
    echo
    echo "Enable or disable the NordVPN icon in the system tray."
    echo "The icon provides quick access to basic controls and VPN status details."
    echo
    setting_change "tray"
}
function autoconnect_setting {
    heading "AutoConnect"
    parent="Settings"
    echo "Automatically connect to the VPN on startup."
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec."
        echo "The Auto-Connect location must support obfuscation."
        echo
    fi
    if [[ "$autoconnect" == "disabled" ]]; then
        echo "Choose a location before enabling the setting."
        echo "Connect to any Country, City, Server, or Group."
        echo "eg. Australia or Sydney or au731 or P2P"
        echo
        echo -e "${FColor}(Hit 'Enter' for default or '$upmenu' to quit.)${Color_Off}"
        echo
        if [[ -n $acwhere ]]; then
            echo -e "Default: ${LColor}$acwhere${Color_Off}"
        else
            echo -e "Default: ${LColor}Automatic${Color_Off}"
        fi
        echo
        echo "(The input location will remain as default until the script exits.)"
        echo
        read -r -p "Enter the Auto-Connect location: "; echo
        parent_menu
        acwhere=${REPLY:-$acwhere}
    fi
    setting_change "autoconnect"
}
function ipv6_setting {
    heading "IPv6"
    echo "Enable or disable NordVPN IPv6 support."
    echo
    echo "Also refer to:"
    echo "https://support.nordvpn.com/hc/en-us/articles/20164669224337"
    echo
    setting_change "ipv6"
}
function customdns_menu {
    heading "Custom-DNS"
    parent="Settings"
    echo "The NordVPN app automatically uses NordVPN DNS servers"
    echo "to prevent DNS leaks. (103.86.96.100 and 103.86.99.100)"
    echo "You can specify your own Custom-DNS servers instead."
    echo
    if [[ "$tplite" == "enabled" ]]; then
        echo -e "$tp - ${WColor}Note:${Color_Off} Enabling Custom-DNS disables TPLite."
        echo
    fi
    if [[ "$customdns" == "enabled" ]]; then
        echo -e "$dns Custom-DNS is ${EColor}$customdns${Color_Off}."
        echo -e "Current DNS: ${DNSColor}$dns_servers${Color_Off}"
    else
        echo -e "$dns Custom-DNS is ${DColor}$customdns${Color_Off}."
    fi
    echo
    PS3=$'\n''Choose an option: '
    # Note submcdns[@] - new entries should keep the same format for the "Test Servers" option
    # eg Name<space>DNS1<space>DNS2
    submcdns=("Nord 103.86.96.100 103.86.99.100" "Nord-TPLite 103.86.96.96 103.86.99.99" "OpenDNS 208.67.220.220 208.67.222.222" "CB-Security 185.228.168.9 185.228.169.9" "AdGuard 94.140.14.14 94.140.15.15" "Quad9 9.9.9.9 149.112.112.11" "Cloudflare 1.0.0.1 1.1.1.1" "Google 8.8.4.4 8.8.8.8" "Specify or Default" "Disable Custom-DNS" "Flush DNS Cache" "Test Servers" "Exit")
    select cdns in "${submcdns[@]}"
    do
        parent_menu
        echo
        case $cdns in
            "Nord 103.86.96.100 103.86.99.100")
                setting_enable "dns" "103.86.96.100 103.86.99.100"
                ;;
            "Nord-TPLite 103.86.96.96 103.86.99.99")
                setting_enable "dns" "103.86.96.96 103.86.99.99"
                ;;
            "OpenDNS 208.67.220.220 208.67.222.222")
                setting_enable "dns" "208.67.220.220 208.67.222.222"
                ;;
            "CB-Security 185.228.168.9 185.228.169.9")
                # Clean Browsing Security 185.228.168.9 185.228.169.9
                # Clean Browsing Adult 185.228.168.10 185.228.169.11
                # Clean Browsing Family 185.228.168.168 185.228.169.168
                setting_enable "dns" "185.228.168.9 185.228.169.9"
                ;;
            "AdGuard 94.140.14.14 94.140.15.15")
                setting_enable "dns" "94.140.14.14 94.140.15.15"
                ;;
            "Quad9 9.9.9.9 149.112.112.11")
                setting_enable "dns" "9.9.9.9 149.112.112.11"
                ;;
            "Cloudflare 1.0.0.1 1.1.1.1")
                setting_enable "dns" "1.0.0.1 1.1.1.1"
                ;;
            "Google 8.8.4.4 8.8.8.8")
                setting_enable "dns" "8.8.4.4 8.8.8.8"
                ;;
            "Specify or Default")
                heading "Specify or Default" "txt"
                echo "Enter up to three DNS IPs separated by spaces."
                echo
                echo -e "${FColor}(Hit 'Enter' for default or '$upmenu' to quit.)${Color_Off}"
                echo
                echo -e "Default: ${FColor}$dnsdesc ${DNSColor}$default_dns${Color_Off}"
                echo
                read -r -p "Up to 3 DNS server IPs: "; echo
                parent_menu
                if [[ -n "$REPLY" ]]; then
                    setting_enable "dns" "$REPLY"
                else
                    setting_enable "dns"
                fi
                ;;
            "Disable Custom-DNS")
                setting_disable "dns" "showstatus"
                ;;
            "Flush DNS Cache")
                heading "Flush DNS Cache" "txt"
                echo -e "${LColor}sudo resolvectl flush-caches${Color_Off}"
                echo -e "${FColor}(CTRL-C x4 to quit)${Color_Off}"
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
                heading "Test Servers" "txt"
                echo "Test DNS response time by looking up a hostname."
                echo
                echo -e "${FColor}(Hit 'Enter' for default or '$upmenu' to quit.)${Color_Off}"
                echo
                echo -e "Default: ${LColor}$default_dnshost${Color_Off}"
                echo
                read -r -p "Enter any hostname: "; echo
                parent_menu
                testhost=${REPLY:-$default_dnshost}
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
    done
}
function landiscovery_setting {
    heading "LAN-Discovery"
    echo
    echo "Access printers, TVs, and other devices on your LAN while connected to"
    echo "the VPN, using Meshnet traffic routing, or with the Kill Switch enabled."
    echo
    echo "Automatically allow traffic from these private subnets:"
    echo "10.0.0.0/8  169.254.0.0/16  172.16.0.0/12  192.168.0.0/16"
    echo
    if [[ "$allowlist_var" == "enabled" && "$landiscovery" == "disabled" ]]; then
        echo -e "$al - ${WColor}Note:${Color_Off} Enabling LAN-Discovery removes private subnets from Allowlist."
        echo
        echo -e "${EColor}Current Allowlist:${Color_Off}"
        printf '%s\n' "${allowlist[@]}"
        echo
    fi
    setting_change "lan-discovery"
}
function virtual_setting {
    heading "Virtual-Location"
    echo "Enable or disable the use of virtual servers."
    echo
    echo "Virtual servers let you connect to more places worldwide."
    echo "Physical servers are placed outside the virtual location"
    echo "but are configured to use an IP address from that location."
    echo
    echo "Refer to: https://nordvpn.com/blog/new-nordvpn-virtual-servers/"
    echo
    if ! app_exists "unbuffer"; then
        echo -e "${WColor}The 'unbuffer' utility could not be found.${Color_Off}"
        echo "This utility is used to process Virtual Locations."
        echo "Please install the 'expect' package, for example:"
        echo -e "${EColor}sudo apt install expect${Color_Off}"
        echo
    fi
    setting_change "virtual-location"
}
function postquantum_setting {
    # disconnect VPN when changing setting.  https://github.com/NordSecurity/nordvpn-linux/issues/637
    # if $postquantum is enabled, the technology is NordLynx and Meshnet is disabled
    heading "Post-Quantum"
    echo "Post-Quantum VPN uses cutting-edge cryptography designed to resist"
    echo "quantum computer attacks.  Refer to:"
    echo "https://nordvpn.com/blog/nordvpn-linux-post-quantum-encryption-support/"
    echo
    echo "Not compatible with OpenVPN, NordWhisper, Meshnet, or Dedicated-IP."
    echo
    if [[ "$status" == "connected" || "$technology" != "nordlynx" || "$meshnet" == "enabled" ]] ; then
        echo -e "$pq Post-Quantum VPN is $postquantumc."
        echo
        echo -e "The VPN is $statusc."
        if [[ "$postquantum" == "enabled" ]]; then
            echo
            echo -e "${WColor}To disable Post-Quantum VPN you must disconnect from VPN.${Color_Off}"
        else
            echo -e "The Technology is set to $techpro."
            echo -e "$mn Meshnet is $meshnetc."
            echo
            echo -e "${WColor}To enable Post-Quantum VPN you must disconnect from VPN and"
            echo -e "use NordLynx Technology with Meshnet disabled.${Color_Off}"
        fi
        echo
        read -n 1 -r -p "Proceed? (y/n) "; echo
        echo
        #
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            techpro_set "NordLynx" "UDP"    # will disconnect
            setting_disable "meshnet" "showstatus"
        else
            setting_menu
        fi
        #
    fi
    setting_change "post-quantum"
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
        echo -e "$ld LAN-Discovery is ${EColor}enabled${Color_Off}."
        echo -e "Allowlisting a private subnet is not available."
        echo
    fi
    echo -e "${EColor}Current Allowlist:${Color_Off}"
    if [[ -n "${allowlist[*]}" ]]; then
        printf '%s\n' "${allowlist[@]}"
    else
        echo -e "$al No allowlist entries."
    fi
    echo
    echo -e "${LColor}function allowlist_commands${Color_Off}"
    #
    allowloc="$0"
    if [[ "$externalsource" =~ ^[Yy]$ ]]; then
        if [[ -f "$configfile" ]] && grep -iq "function allowlist_commands {" "$configfile"; then
            allowloc="$configfile"
            echo -e "${FColor}Source: $configfile${Color_Off}"
        fi
    fi
    startline=$(grep -m1 -n "allowlist_start" "$allowloc" | cut -f1 -d':')
    endline=$(( $(grep -m1 -n "allowlist_end" "$allowloc" | cut -f1 -d':') - 1 ))
    numlines=$(( endline - startline ))
    if app_exists "highlight"; then
        highlight -l -O xterm256 "$allowloc" | head -n "$endline" | tail -n "$numlines"
    else
        cat -n "$allowloc" | head -n "$endline" | tail -n "$numlines"
    fi
    echo
    echo -e "Type ${WColor}C${Color_Off} to clear the current allowlist."
    echo -e "Type ${FIColor}E${Color_Off} to edit the script."
    echo
    read -n 1 -r -p "Apply your default allowlist settings? (y/n/C/E) "; echo
    echo
    parent_menu "$1"
    case "$REPLY" in
        [Yy])
            allowlist_commands
            set_vars
            ;;
        [Cc])
            nordvpn allowlist remove all
            set_vars
            ;;
        [Ee])
            echo -e "${FColor}$allowloc${Color_Off}"
            echo -e "Modify ${LColor}function allowlist_commands${Color_Off} starting on ${FColor}line $(( startline + 1 ))${Color_Off}"
            openlink "$allowloc" "noask" "exit"
            ;;
        *)
            echo "No changes made."
            ;;
    esac
    echo
    if [[ -n "${allowlist[*]}" ]]; then
        echo -e "${EColor}Current Allowlist:${Color_Off}"
        printf '%s\n' "${allowlist[@]}"
    fi
    if [[ "$1" == "back" ]]; then
        return
    fi
    main_menu
}
#
# =====================================================================
#
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
                echo
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
#
# =====================================================================
#
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
    echo -e "${WColor}"
    echo "Disable the kill switch"
    echo "Disconnect"
    echo "Logout"
    echo "'nordvpn allowlist remove all'"
    echo "'nordvpn set defaults'"
    echo "Restart the nordvpnd service"
    echo "Login"
    echo "Apply your default configuration"
    echo -e "${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setting_disable "killswitch"
        disconnect_vpn "force"
        logout_nord
        nordvpn allowlist remove all
        echo
        nordvpn set defaults
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
    setting_menu
}
function script_info {
    # display the customization options from the top of the script
    # if externalsource is used, display the contents and a side-by-side diff
    echo
    echo -e "${EColor}$0${Color_Off}"
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
    if [[ "$externalsource" =~ ^[Yy]$ ]] && [[ -f "$configfile" ]]; then
        echo
        echo -e "${WColor}External Source In Use:${Color_Off}"
        echo -e "${FColor}$configfile${Color_Off}"
        echo
        if app_exists "highlight"; then
            highlight -l -O xterm256 "$configfile"
        else
            cat -n "$configfile"
        fi
        echo
        echo "Diff - comments outside functions are ignored"
        echo -e "Left = Defaults ${DColor}$0${Color_Off}"
        echo -e "Right = Config ${EColor}$configfile${Color_Off}"
        if ! command -v colordiff &> /dev/null; then
            echo "'sudo apt install colordiff' to add colors."
            echo
            diff --side-by-side <(awk '!/^#/ && !/^$/ { print } /End Diff/ { exit }' "$0") <(awk '!/^#/ && !/^$/ { print } /End Diff/ { exit }' "$configfile")
        else
            echo
            diff --side-by-side <(awk '!/^#/ && !/^$/ { print } /End Diff/ { exit }' "$0") <(awk '!/^#/ && !/^$/ { print } /End Diff/ { exit }' "$configfile") | colordiff
        fi
        echo
        openlink "$configfile" "ask" "exit"
    fi
    echo
    openlink "$0" "ask" "exit"
    setting_menu
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
        heading "Set Defaults: ${H2Color}Custom-DNS${H1Color}" "txt"
        read -n 1 -r -p "Go to the Custom-DNS setting? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            set_vars
            customdns_menu
        fi
        main_menu
    fi
}
#
# =====================================================================
#
function iptables_status {
    echo
    main_logo "stats_only"
    echo -e "Firewall Mark: ${LColor}$fwmark${Color_Off}"
    echo
    if [[ -n "${allowlist[*]}" ]]; then
        printf '%s\n' "${allowlist[@]}"
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
    echo -e "${FColor}Restart the service and reconnect VPN to recreate the iptables rules.${Color_Off}"
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
                iptables_status
                ;;
            "Firewall")
                echo
                setting_change "firewall" "back"
                iptables_status
                ;;
            "Routing")
                echo
                setting_change "routing" "back"
                iptables_status
                ;;
            "KillSwitch")
                echo
                setting_change "killswitch" "back"
                iptables_status
                ;;
            "Meshnet")
                echo
                setting_change "meshnet" "back"
                iptables_status
                ;;
            "LAN-Discovery")
                echo
                setting_change "lan-discovery" "back"
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
                        setting_change "autoconnect" "back"
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
                if [[ "$status" == "connected" ]]; then
                    read -n 1 -r -p "$(echo -e "${WColor}Disconnect the VPN?${Color_Off} (y/n) ")"; echo
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        disconnect_vpn "force"
                    fi
                fi
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
#
# =====================================================================
#
function favorites_verify {
    parent="Favorites"
    heading "Check for Obsolete Favorites" "txt" "alt"
    echo -e "Compare: ${EColor}$favoritesfile${Color_Off}"
    echo "Last Modified: $( date -r "$favoritesfile" )"
    echo -e "Against: ${EColor}$serversfile${Color_Off}"
    echo "Last Modified: $( date -r "$serversfile" )"
    echo
    echo "Check if any hostnames have been removed from service."
    echo "You will be prompted to delete any obsolete servers from"
    echo "the favorites list."
    echo
    echo "============================================================"
    echo "Backup and update the JSON file."
    echo "Recommended if you've added favorites since the last update."
    echo
    if [[ ! -f "$serversfile" ]]; then
        echo -e "${WColor}$(basename "$serversfile") does not exist.${Color_Off}"
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
    backup_file "$favoritesfile"
    echo
    echo "============================================================"
    echo "Comparing your favorites with $(basename "$serversfile"):"
    echo
    # extract hostnames.  this speeds up the process significantly since we only search the json once
    hostnames="$(jq -r '.[].hostname' "$serversfile")"
    #
    # loop through lines in favoritesfile
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
            read -n 1 -r -p "$(echo -e "${WColor}Delete${Color_Off}") $line from '$(basename "$favoritesfile")'? (y/n): "
            echo
            if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                # delete the line using awk.  tried using 'sed -i' but had problems with special characters
                awk -v pattern="$line" '$0 != pattern' "$favoritesfile" >favtemp && mv favtemp "$favoritesfile"
                echo -e "$line ${WColor}deleted${Color_Off}"
                echo
            else
                echo -e "${EIColor}Keep${Color_Off} $line"
                echo
            fi
        fi
    done 3< <(sort < "$favoritesfile")
    echo
    echo "Completed."
    echo
    echo
    # reload the favorites menu in case favoritesfile has changed
    read -n 1 -s -r -p "Press any key to continue... "; echo
    favorites_menu
}
function favorites_menu {
    heading "Favorites"
    parent="Main"
    main_logo "stats_only"
    echo "Keep track of your favorite individual servers by adding them to"
    echo "this list. For example low ping servers or streaming servers."
    echo
    if [[ -f "$favoritesfile" ]]; then
        # remove leading and trailing spaces and tabs, delete empty lines
        # prevent sed from changing the "Last Modified" file property unless it actually makes changes
        if ! cmp -s "$favoritesfile" <( sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' -e '/^$/d' "$favoritesfile" ); then
            sed -i -e 's/^[ \t]*//' -e 's/[ \t]*$//' -e '/^$/d' "$favoritesfile"
        fi
    else
        echo -e "${WColor}$favoritesfile does not exist.${Color_Off}"
        echo
        read -n 1 -r -p "Create the file? (y/n) "; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            touch "$favoritesfile"
            favorites_menu
        else
            main_menu
        fi
    fi
    # return to favorites_menu after any change so that the array is updated.  (used for main_logo "Favorite" label)
    readarray -t favoritelist < <( sort < "$favoritesfile" )
    #
    if (( "${#favoritelist[@]}" > 1 )); then
        rfavorite=$( printf '%s\n' "${favoritelist[ RANDOM % ${#favoritelist[@]} ]}" )
        favoritelist+=( "Random" )
    fi
    if [[ "$status" == "connected" ]]; then
        if grep -q -i "$server" "$favoritesfile"; then
            echo -e "The Current Server is in the list:  ${FColor}$( grep -i "$server" "$favoritesfile" )${Color_Off}"
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
                openlink "$favoritesfile" "ask" "exit"
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
                    echo "$REPLY" >> "$favoritesfile"
                    echo
                    echo -e "Added ${FColor}$REPLY${Color_Off} to ${LColor}$favoritesfile${Color_Off}"
                    echo
                else
                    echo -e "${DColor}(Skipped)${Color_Off}"
                    echo
                fi
                favorites_menu
                ;;
            "Add Current Server")
                favdefault="$(echo "$city" | tr -d ' _')_$server"  # remove any space or underscore
                #
                heading "Add $server to Favorites" "txt"
                echo -e "Format:  AnyName${H2Color}<underscore>${Color_Off}ActualServerNumber"
                echo "Examples:  Netflix_$server  Gaming_$server"
                echo -e "Note: The ${EColor}_$server${Color_Off} part will be added automatically."
                echo
                echo -e "${FColor}(Hit 'Enter' for default or '$upmenu' to quit)${Color_Off}"
                echo
                echo -e "Default: ${LColor}$favdefault${Color_Off}"
                echo
                read -r -p "Enter the server name: " favadd
                if [[ "$favadd" = "$upmenu" ]]; then
                    favorites_menu
                fi
                favadd=${favadd:-$favdefault}
                if [[ "$favadd" != *"$server"* ]]; then
                    favadd="${favadd}_${server}"
                fi
                echo "$favadd" >> "$favoritesfile"
                echo
                echo -e "Added ${FColor}$favadd${Color_Off} to ${LColor}$favoritesfile${Color_Off}"
                echo
                favorites_menu
                ;;
            "Random")
                heading "Random"
                echo
                disconnect_vpn
                echo "Connect to $rfavorite"
                echo
                nordvpn connect "${rfavorite##*_}"  # everything after the last underscore
                exit_status
                exit
                ;;
            *)
                if (( 1 <= REPLY )) && (( REPLY <= ${#favoritelist[@]} )); then
                    heading "${xfavorite%_*}"   # everything before the last underscore
                    echo
                    disconnect_vpn
                    echo "Connect to $xfavorite"
                    echo
                    nordvpn connect "${xfavorite##*_}"  # everything after the last underscore
                    exit_status
                    exit
                else
                    invalid_option "${#favoritelist[@]}" "$parent"
                fi
                ;;
        esac
    done
}
#
# =====================================================================
#
function create_list_virtual {
    # create the virtual_countries or virtual_cities associative array
    # $1 = "countries" - virtual locations in "nordvpn countries"
    # $1 = "cities" - virtual locations in "nordvpn cities $xcountry"
    #
    if [[ "$virtual" != "enabled" ]] || ! app_exists "unbuffer"; then
        return
    fi
    #
    if [[ "$1" == "countries" ]]; then
        nvcommand=( unbuffer nordvpn countries )
    elif [[ "$1" == "cities" && -n "$xcountry" ]]; then
        nvcommand=( unbuffer nordvpn cities "$xcountry" )
    else
        echo -e "${WColor}Invalid argument. ($1) ($xcountry)${Color_Off}"; echo
        return 1
    fi
    # the nordvirtual array holds the blue-colored elements (virtual locations)
    readarray -t nordvirtual < <(
        # Execute the command as an array
        "${nvcommand[@]}" |
        cat -v |
        awk '{
            for (i=1; i<=NF; i++) {
                # Check if the field contains "94m"
                if ($i ~ /94m/) {
                    # Remove everything before and including "94m"
                    sub(/.*94m/, "", $i)
                    # Remove everything after and including "^"
                    sub(/\^.*$/, "", $i)
                    # Exclude last line: ^[[94m* Virtual location servers^[[0m
                    if ($i != "*") {
                        print $i
                    }
                }
            }
        }'
    )
    # create the associative array
    if [[ "$1" == "countries" ]]; then
        for vcountry in "${nordvirtual[@]}"; do
            virtual_countries["${vcountry}"]=1
        done
    elif [[ "$1" == "cities" ]]; then
        for vcity in "${nordvirtual[@]}"; do
            virtual_cities["${vcity}"]=1
        done
    fi
}
function create_list_country {
    # Create three arrays:
    # countrylist = all the countries from the "nordvpn countries" command output
    # virtual_countries = assoc. array of virtual countries based on the blue color in the "nordvpn countries" output
    # modcountrylist = modified country names for the "Countries" selection menu.  shortened names and/or marked with an asterisk.
    #
    countrylist=()
    declare -gA virtual_countries=()
    modcountrylist=()
    virtualnote="false"
    #
    readarray -t countrylist < <(
        nordvpn countries |
        awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' |
        sort
    )
    rcountry=$( printf '%s\n' "${countrylist[ RANDOM % ${#countrylist[@]} ]}" )
    if [[ "$1" == "count" ]]; then
        return
    fi
    countrylist+=( "Random" "Exit" )
    #
    # create the virtual_countries associative array
    create_list_virtual "countries"
    #
    # create the modcountrylist array
    for mcountry in "${countrylist[@]}"; do
        # Check if the country is in the virtual set
        if [[ -n "${virtual_countries[${mcountry}]}" ]]; then
            # Add an asterisk to the country name
            mcountry="${mcountry}*"
            virtualnote="true"
        fi
        #
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
function create_list_city {
    # Create three arrays:
    # citylist = all the cities from the "nordvpn cities $xcountry" command output
    # virtual_cities = assoc. array of virtual cities based on the blue color in the "nordvpn cities $xcountry" output
    # modcitylist = mark virtual cities with an asterisk, for the city selection menu
    #
    if [[ -z "$xcountry" ]]; then
        echo -e "${WColor}No country specified.${Color_Off}"; echo
        exit 1
    fi
    #
    citylist=()
    declare -gA virtual_cities=()
    modcitylist=()
    virtualnote="false"
    #
    readarray -t citylist < <(
        nordvpn cities "$xcountry" |
        awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' |
        sort
    )
    rcity=$( printf '%s\n' "${citylist[ RANDOM % ${#citylist[@]} ]}" )
    if [[ "$1" == "count" ]]; then
        return
    fi
    if (( "${#citylist[@]}" > 1 )); then
        citylist+=( "Random" "Best" )
    fi
    citylist+=( "Exit" )
    #
    # create the virtual_cities associative array
    create_list_virtual "cities"
    #
    # Create the modcitylist array
    for mcity in "${citylist[@]}"; do
        # Check if the city is in the virtual set
        if [[ -n "${virtual_cities[${mcity}]}" ]]; then
            # Add an asterisk to the city name
            mcity="${mcity}*"
            virtualnote="true"
        fi
        # Add the modified city name to modcitylist. includes "Random" "Best" "Exit"
        modcitylist+=( "$mcity" )
    done
}
function create_list_group {
    # Create an array containing all the available groups
    # Group availablility changes with settings, eg. obfuscate
    readarray -t grouplist < <(
        nordvpn groups |
        awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' |
        sort
    )
    grouplist+=( "Exit" )
}
function country_name_restore {
    # countrylist and modcountrylist store two names for the same country at the same index
    # in country_menu, xcountry is selected from modcountrylist (abbreviated and/or with asterisk)
    #
    # iterate over modcountrylist to find the index
    for i in "${!modcountrylist[@]}"; do
        if [[ "${modcountrylist[i]}" == "${xcountry}" ]]; then
            index=$i
            break
        fi
    done
    # restore the original country name from the countrylist array
    xcountry="${countrylist[index]}"
    #
}
function city_name_restore {
    # in city_menu, xcity is selected from modcitylist and may have an asterisk
    #
    # check if the last character is an asterisk
    if [[ "${xcity: -1}" == "*" ]]; then
        # remove the last character
        xcity="${xcity::-1}"
    fi
}
function country_menu {
    # submenu for all available countries
    #
    heading "Countries"
    parent="Main"
    create_list_country
    #
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Countries with Obfuscation support"
        echo
    fi
    virtual_note
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
            country_name_restore
            city_menu
        else
            invalid_option "${#modcountrylist[@]}" "$parent"
        fi
    done
}
function city_menu {
    # all available cities in $xcountry
    # $1 = parent menu name - valid options are listed in function parent_menu
    #      disables fast_country (automatic connect to country)
    #
    if [[ -n "$1" ]]; then
        parent="$1"
    else
        parent="Country"
    fi
    heading "$xcountry"
    echo
    if [[ "$fast_country" =~ ^[Yy]$ && -z "$1" ]]; then
        echo -e "${FColor}fast_country is enabled. Connect to the country not a city.${Color_Off}"
        echo
        echo -e "Connect to ${LColor}$xcountry${Color_Off}"
        echo
        disconnect_vpn
        nordvpn connect "$xcountry"
        exit_status
        exit
    fi
    create_list_city
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Cities in $xcountry with Obfuscation support"
        echo
    fi
    virtual_note
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
                echo
                disconnect_vpn
                echo "Connect to the best available city."
                echo
                nordvpn connect "$xcountry"
                exit_status
                exit
                ;;
            "Random")
                heading "Random"
                echo
                disconnect_vpn
                echo "Connect to $rcity $xcountry"
                echo
                nordvpn connect "$rcity"
                exit_status
                exit
                ;;
            *)
                if (( 1 <= REPLY )) && (( REPLY <= ${#modcitylist[@]} )); then
                    city_name_restore
                    heading "$xcity"
                    echo
                    disconnect_vpn
                    echo "Connect to $xcity $xcountry"
                    echo
                    nordvpn connect "$xcity"
                    exit_status
                    exit
                else
                    invalid_option "${#modcitylist[@]}" "$parent"
                fi
                ;;
        esac
    done
}
#
# =====================================================================
#
function group_location {
    # $1 = $1 from function group_connect (Nord group name)
    #
    heading "Set $1 Location" "txt" "alt"
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
            echo "A Dedicated-IP subscription is required."
            echo "Enter your assigned server.  eg 'ca1692'"
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
            echo "Connect to your assigned server to use a personal IP address that"
            echo "belongs only to you.  Purchasing a subscription is required."
            location="$dipwhere"
            ;;
    esac
    echo
    indicators_display "short"
    echo
    echo "To connect to the $1 group the following"
    echo "changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    case "$1" in
        "Obfuscated_Servers")
            # OpenVPN only
            echo "Set Post-Quantum to disabled."
            echo "Set Technology to OpenVPN TCP or UDP."
            echo "Set Obfuscate to enabled."
            ;;
        "Double_VPN" | "Dedicated_IP")
            # exclude NordWhisper. Double-VPN fails with PQ enabled. Dedicated-IP is not compatible with PQ.
            echo "Set Technology to OpenVPN or NordLynx."
            echo "Set Post-Quantum to disabled."
            echo "Set Obfuscate to disabled."
            ;;
        "Onion_Over_VPN")
            # exclude NordWhisper.  works OK with PQ
            echo "Set Technology to OpenVPN or NordLynx."
            echo "Set NordLynx Post-Quantum (choice)."
            echo "Set Obfuscate to disabled."
            ;;
        "P2P")
            # available with all technologies and PQ
            echo "Choose a Technology and Protocol."
            echo "Set NordLynx Post-Quantum (choice)."
            echo "Set Obfuscate to disabled."
            ;;
    esac
    echo "Set the Kill Switch (choice)."
    echo -e "Connect to the $1 group ${EColor}$location${Color_Off}"
    echo -e "${LColor}(Type ${FIColor}S${LColor} to specify a location)${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n/S) "; echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        group_location "$1"
    fi
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        case "$1" in
            "Obfuscated_Servers")
                # OpenVPN only
                techpro_menu "back" "ovpn"
                setting_enable "obfuscate" "showstatus"
                ;;
            "Double_VPN" | "Dedicated_IP")
                # exclude NordWhisper
                techpro_menu "back" "xnw"
                # Double-VPN fails with PQ enabled. Dedicated-IP is not compatible with PQ.
                # Choosing NordLynx will always prompt to enable post-quantum. Ensure PQ is disabled.
                if [[ "$postquantum" == "enabled" ]]; then
                    echo -e "${WColor}Note:${Color_Off} Post-Quantum VPN is not compatible with $1."
                    echo
                    setting_disable "post-quantum"
                fi
                setting_disable "obfuscate"
                ;;
            "Onion_Over_VPN")
                # exclude NordWhisper.  works OK with PQ
                techpro_menu "back" "xnw"
                setting_disable "obfuscate"
                ;;
            "P2P")
                # available with all technologies and PQ
                techpro_menu "back"
                setting_disable "obfuscate"
                ;;
        esac
        setting_change "killswitch" "back"
        echo -e "Connect to the $1 group ${EColor}$location${Color_Off}"
        echo
        if [[ -n $location ]]; then
            nordvpn connect --group "$1" "$location"
        else
            nordvpn connect --group "$1"
        fi
        exit_status
        exit
    else
        echo "No changes made."
        main_menu
    fi
}
function group_all_menu {
    # all available groups
    heading "All Groups"
    parent="Group"
    create_list_group
    echo
    echo -n "Available With "
    indicators_display "short"
    echo
    PS3=$'\n''Connect to Group: '
    select xgroup in "${grouplist[@]}"
    do
        parent_menu
        if [[ "$xgroup" == "Exit" ]]; then
            main_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#grouplist[@]} )); then
            heading "$xgroup"
            echo
            disconnect_vpn
            echo "Connect to the $xgroup group."
            echo
            nordvpn connect --group "$xgroup"
            exit_status
            exit
        else
            invalid_option "${#grouplist[@]}" "$parent"
        fi
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
#
# =====================================================================
#
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
                echo -e "${WColor}Note:${Color_Off} Transfers will fail if there is a space in the path. (File not found)"
                echo "Workaround: Copy the output command and paste it in a new terminal window."
                #
                meshnet_prompt
                read -r -p "Enter the recipient hostname|nickname|IP|pubkey: " meshwhere
                if [[ -n "$meshwhere" ]]; then
                    echo
                    echo "Enter the full paths and filenames, or try dragging the files from"
                    echo "your file manager to this terminal window."
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
                setting_change "notify" "back"
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
                heading "Enable/Disable Meshnet" "txt"
                #
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
                setting_change "meshnet" "back"
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
                    echo -e "Currently using $techpro."
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
#
# =====================================================================
#
function nordapi_countrycode {
    # find the country code to use as an api filter
    #
    parent="Nord API"
    create_list_country
    # remove the "Random" option leaving just the Countries and "Exit"
    readarray -t modcountrylist < <(printf "%s\n" "${modcountrylist[@]}" | grep -v -e "Random")
    virtual_note
    PS3=$'\n''Choose a Country: '
    select xcountry in "${modcountrylist[@]}"
    do
        parent_menu
        if [[ "$xcountry" == "Exit" ]]; then
            main_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#modcountrylist[@]} )); then
            country_name_restore
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
    # get the country code and set $xcountry for create_list_city
    nordapi_countrycode
    create_list_city
    # remove "Random" and "Best" options, leaving just the cities and "Exit"
    readarray -t modcitylist < <(printf "%s\n" "${modcitylist[@]}" | grep -v -e "Random" -e "Best")
    virtual_note
    PS3=$'\n''Choose a City: '
    # must use $xcity for city_name_restore
    select xcity in "${modcitylist[@]}"
    do
        parent_menu
        if [[ "$xcity" == "Exit" ]]; then
            main_menu
        elif (( 1 <= REPLY )) && (( REPLY <= ${#modcitylist[@]} )); then
            city_name_restore
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
    if [[ "$status" == "connected" ]]; then
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
                host_change
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
function city_count {
    #
    heading "All Countries and Cities by using Nord CLI" "txt"
    #
    allcountries=()
    allcities=()
    virtualcountries=()
    virtualcities=()
    #
    create_list_country "count"         # countrylist[@] = list of all countries
    create_list_virtual "countries"     # virtual_countries[@] = list of all virtual countries
    #
    for xcountry in "${countrylist[@]}"
    do
        is_virtual_country=""
        if [[ -n "${virtual_countries[${xcountry}]}" ]]; then
            is_virtual_country="*"
        fi
        echo "$xcountry$is_virtual_country"
        allcountries+=( "$xcountry$is_virtual_country" )
        [[ -n "$is_virtual_country" ]] && virtualcountries+=( "$xcountry$is_virtual_country" )
        #
        create_list_city "count"        # citylist[@] = list of all cities in $xcountry
        create_list_virtual "cities"    # virtual_cities[@] = list of all virtual cities in $xcountry
        #
        for xcity in "${citylist[@]}"; do
            is_virtual_city=""
            if [[ -n "${virtual_cities[${xcity}]}" ]]; then
                is_virtual_city="*"
            fi
            echo "    $xcity$is_virtual_city"
            formatted_pair="$xcity$is_virtual_city $xcountry$is_virtual_country"    # sort by city / country
            #formatted_pair="$xcountry$is_virtual_country $xcity$is_virtual_city"    # sort by country / city
            allcities+=( "$formatted_pair" )
            [[ -n "$is_virtual_city" ]] && virtualcities+=( "$formatted_pair" )
        done
        echo
    done
    #
    heading "All Countries (${#allcountries[@]})" "txt"
    printf '%s\n' "${allcountries[@]}" | sort
    #
    heading "All Cities (${#allcities[@]})" "txt"
    printf '%s\n' "${allcities[@]}" | sort
    #
    if [[ "$virtual" == "enabled" && ${#virtualcountries[@]} -gt 0 ]]; then
        heading "Virtual Countries (${#virtualcountries[@]})" "txt"
        printf '%s\n' "${virtualcountries[@]}" | sort
    fi
    #
    if [[ "$virtual" == "enabled" && ${#virtualcities[@]} -gt 0 ]]; then
        heading "Virtual Cities (${#virtualcities[@]})" "txt"
        printf '%s\n' "${virtualcities[@]}" | sort
    fi
    # Buenos_Aires Argentina, Tbilisi Georgia
    echo
    echo "========================="
    echo "Total Countries    = ${#allcountries[@]}"
    echo "      Cities       = ${#allcities[@]}"
    echo
    echo "Physical Countries = $(( ${#allcountries[@]} - ${#virtualcountries[@]} ))"
    echo "         Cities    = $(( ${#allcities[@]} - ${#virtualcities[@]} ))"
    echo
    echo "Virtual Countries* = ${#virtualcountries[@]}"
    echo "        Cities*    = ${#virtualcities[@]}"
    echo "========================="
    echo
    if [[ "$virtual" == "disabled" ]]; then
        echo -e "$vl Virtual-Location is ${DColor}disabled${Color_Off}."
        echo
    fi
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec."
        echo "These locations have Obfuscation support."
        echo
    fi
}
function host_change {
    heading "Change Host" "txt"
    echo "Change the Hostname for testing purposes."
    echo
    if [[ "$status" == "connected" ]]; then
        echo -e "Connected to: ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    echo "Choose a new Hostname/IP for testing"
    read -r -p "Hit 'Enter' for default [$default_vpnhost]: " nordhost
    nordhost=${nordhost:-$default_vpnhost}
    echo
    echo -e "Now using ${LColor}$nordhost${Color_Off} for testing."
    echo "(Does not affect 'Rate VPN Server')"
    echo
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
    echo
    disconnect_vpn
    echo "Connect to $connecthost"
    echo
    nordvpn connect "$connecthost"
    exit_status
    # add testing commands here
    #
    # https://streamtelly.com/check-netflix-region/
    echo "Netflix Region and Status"
    curl --silent "http://api-global.netflix.com/apps/applefuji/config" | grep -E 'geolocation.country|geolocation.status'
    echo
    #
}
#
# =====================================================================
#
function allservers_update {
    # download an updated json file of all the nordvpn servers
    # if a backup file was created, compare it with the new json to see if any hostnames were added or removed
    #
    # backup the current json
    backup_file "$serversfile"
    #
    read -n 1 -r -p "Download an updated .json? (~20MB) (y/n) "; echo
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl "https://api.nordvpn.com/v1/servers?limit=9999999" > "$serversfile"
        echo
        echo -e "Saved as: ${EColor}$serversfile${Color_Off}"
        echo "File Size: $( du -k "$serversfile" | cut -f1 ) KB"
        echo "Last Modified: $( date -r "$serversfile" )"
        echo -n "Server Count: "
        jq length "$serversfile"
        echo
    fi
    if [[ -f "$backupfile" ]]; then
        #
        oldfile="$backupfile"
        newfile="$serversfile"
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
function allservers_group {
    # query the local json to list and count the servers in a specified group
    # $1 = exact group name - "Double VPN" "Onion Over VPN" "Obfuscated Servers" "P2P" "Dedicated IP"
    # $2 = "quotes" - keep the double quotes to use the list elsewhere
    #
    heading "Group: $1" "txt"
    if [[ "$2" == "quotes" ]]; then
        jq --arg group "$1" '.[] | select(.groups[].title == $group) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -k2
    else
        jq -r --arg group "$1" '.[] | select(.groups[].title == $group) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -k2
    fi
    servercount="$( jq -r --arg group "$1" '.[] | select(.groups[].title == $group) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -u | wc -l )"
    echo
    echo "Servers in Group '$1' = $servercount"
    echo
}
function allservers_technology {
    # query the local json to list and count the servers with a specific technology
    # $1 = exact technology name - "Socks 5" "IKEv2/IPSec" "HTTP Proxy (SSL)" "HTTP CyberSec Proxy (SSL)" "OpenVPN UDP" "OpenVPN TCP" "Wireguard" "NordWhisper"
    # $2 = "quotes" - keep the double quotes to use the list elsewhere
    #
    heading "Technology: $1" "txt"
    if [[ "$2" == "quotes" ]]; then
        jq --arg tech "$1" '.[] | select(.technologies[].name == $tech) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -k2
    else
        jq -r --arg tech "$1" '.[] | select(.technologies[].name == $tech) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -k2
    fi
    servercount="$( jq --arg tech "$1" '.[] | select(.technologies[].name == $tech) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -u | wc -l )"
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
    if [[ -f "$serversfile" ]]; then
        echo -e "File: ${EColor}$serversfile${Color_Off}"
    else
        echo -e "${WColor}$serversfile does not exist.${Color_Off}"
        echo
        read -n 1 -r -p "Download the .json? (~20MB) (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            touch "$serversfile"
            curl "https://api.nordvpn.com/v1/servers?limit=9999999" > "$serversfile"
            echo -e "Saved as: ${EColor}$serversfile${Color_Off}"
        else
            REPLY="$upmenu"
            parent_menu
        fi
    fi
    echo "Last Modified: $( date -r "$serversfile" )"
    echo -n "Server Count: "
    jq length "$serversfile"
    echo
    PS3=$'\n''Choose an option: '
    COLUMNS="$menuwidth"
    submallvpn=( "List All Servers" "Server Count" "Double-VPN Servers" "Onion Servers" "SOCKS Servers" "Obfuscated Servers" "P2P Servers" "Dedicated-IP Servers" "IKEv2/IPSec" "HTTPS Proxy" "HTTPS CyberSec Proxy" "OpenVPN UDP" "OpenVPN TCP" "WireGuard" "NordWhisper" "Virtual Locations" "Search Country" "Search City" "Search Server" "Connect" "Update List" "Exit" )
    select avpn in "${submallvpn[@]}"
    do
        parent_menu
        case $avpn in
            "List All Servers")
                heading "All the VPN Servers" "txt"
                jq -r '.[].hostname' "$serversfile" | sort -V -u
                echo
                echo "All Servers = $( jq length "$serversfile" )"
                echo
                ;;
            "Server Count")
                heading "Servers in each Country" "txt"
                jq -r 'group_by(.locations[0].country.name) | map({country: .[0].locations[0].country.name, total: length}) | sort_by(.country) | .[] | "\(.country) \(.total)"' "$serversfile"
                echo
                heading "Servers in each City" "txt"
                jq -r 'group_by(.locations[0].country.name + " " + .locations[0].country.city.name) | map({country: .[0].locations[0].country.name, city: .[0].locations[0].country.city.name, total: length}) | sort_by(.country, .city) | .[] | "\(.country) \(.city) \(.total)"' "$serversfile"
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
            "NordWhisper")
                allservers_technology "NordWhisper"
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
                    #jq -r --arg searchcountry "$searchcountry" '.[] | select(.locations[].country.name == $searchcountry) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -k2
                    #echo
                    heading "Servers in $searchcountry sorted by Hostname" "txt"
                    jq -r --arg searchcountry "$searchcountry" '.[] | select(.locations[].country.name == $searchcountry) | "\(.hostname) (\(.locations[0].country.city.name))"' "$serversfile" | sort -V -k1
                    echo
                    echo "$searchcountry Servers = $( jq -r --arg searchcountry "$searchcountry" '.[] | select(.locations[].country.name == $searchcountry) | .hostname' "$serversfile" | sort -u | wc -l )"
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
                    jq -r --arg searchcity "$searchcity" '.[] | select(.locations[].country.city.name == $searchcity) | .hostname' "$serversfile" | sort -V
                    echo
                    echo "$searchcity Servers = $( jq -r --arg searchcity "$searchcity" '.[] | select(.locations[].country.city.name == $searchcity) | .hostname' "$serversfile" | sort -u | wc -l )"
                    echo
                fi
                ;;
            "Search Server")
                heading "Search by Server Hostname" "txt"
                echo "The complete record for a particular server stored in:"
                echo -e "${EColor}$serversfile${Color_Off}"
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
                    jq --arg searchserver "$searchserver" '.[] | select(.hostname == $searchserver)' "$serversfile"
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
function virtual_locations {
    heading "Virtual Locations" "txt"
    #
    echo -e "${H2Color}Virtual Country Locations${Color_Off}"
    jq '.[] | select(.specifications[] | .title == "Virtual Location") | .locations[].country.name' "$serversfile" | tr ' ' '_' | sort -u | tr '\n' ' '
    echo; echo
    echo "Virtual Country Locations = $( jq '.[] | select(.specifications[] | .title == "Virtual Location") | .locations[].country.name' "$serversfile" | sort -u | wc -l )"
    echo
    echo
    echo -e "${H2Color}Virtual City Locations${Color_Off}"
    jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.city.name' "$serversfile" | tr ' ' '_' | sort -u | tr '\n' ' '
    echo; echo
    echo "Virtual City Locations = $( jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.city.name' "$serversfile" | tr ' ' '_' | sort -u | wc -l )"
    echo
    echo
    echo -e "${H2Color}Virtual Country and City Locations${Color_Off}"
    jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.name, .locations[0].country.city.name' "$serversfile" | tr ' ' '_' | sort -u | tr '\n' ' '
    echo; echo
    echo "Virtual Country and City Locations = $( jq '.[] | select(.specifications[] | select(.title == "Virtual Location")) | .locations[0].country.name, .locations[0].country.city.name' "$serversfile" | sort -u | wc -l )"
    echo
}
function virtual_note {
    # make a note if virtual servers are in the list
    if [[ "$virtualnote" == "true" ]]; then
        echo -e "${FVColor}(*) = Virtual Servers${Color_Off}"
        echo
    fi
}
#
# =====================================================================
#
function tools_menu {
    heading "Tools"
    parent="Main"
    if [[ "$status" == "connected" ]]; then
        main_logo "stats_only"
        PS3=$'\n''Choose an option: '
    else
        echo -e "(VPN $statusc)"
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
                if [[ "$status" == "connected" ]]; then
                    echo -e "${LColor}VPN Server IP:${Color_Off} $ipaddr"
                    echo
                    if [[ "$customdns" != "disabled" ]]; then
                        echo -e "$dns Current DNS: ${DNSColor}$dns_servers${Color_Off}"
                        echo
                    fi
                else
                    echo -e "(VPN $statusc)"
                    echo
                fi
                echo -e "${EColor}ipleak.net DNS Detection: ${Color_Off}"
                echo -e "${Color_Off}$( timeout 6 curl --silent https://"$ipleak_session"-"$RANDOM".ipleak.net/dnsdetection/ | jq .ip )"
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
                host_change
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
    elif [[ "$status" != "connected" || "$technology" != "nordlynx" ]]; then
        echo -e "The VPN is $statusc."
        echo -e "The Technology is set to $techpro."
        echo -e "${WColor}Must connect to your chosen server using NordLynx.${Color_Off}"
        echo
        return
    elif [[ -f "$wgfull" ]]; then
        echo -e "Current Server: ${EColor}$nordhost${Color_Off}"
        echo
        echo -e "${WColor}$wgfull already exists${Color_Off}"
        echo
        openlink "$wgdir" "ask"
        return
    elif [[ "$meshnet" == "enabled" ]]; then
        echo -e "${WColor}Disable the Meshnet NordLynx interfaces and disconnect?${Color_Off}"
        echo "Please reconnect to your chosen server afterwards."
        echo
        setting_change "meshnet" "back"
        if [[ "$meshnet" == "disabled" ]]; then
            main_disconnect
        else
            return
        fi
    fi
    echo -e "Current Server: ${EColor}$nordhost${Color_Off}"
    echo -e "${CIColor}$city${Color_Off} ${COColor}$country${Color_Off} ${IPColor}$ipaddr${Color_Off}"
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
                if [[ "$status" != "connected" ]]; then
                    echo -e "(VPN $statusc)"
                    read -r -p "Enter a Hostname/IP [Default $default_vpnhost]: " nordhost
                    nordhost=${nordhost:-$default_vpnhost}
                    echo
                    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
                    echo
                fi
                if [[ "$status" == "connected" && "$technology" == "openvpn" ]]; then
                    echo -e "$techpro - Server IP will not respond to ping."
                    echo "Attempt to ping the external IP instead."
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
#
# =====================================================================
#
function parent_menu {
    # Return to the previous menu
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
                "Settings")     setting_menu;;
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
function openlink {
    # $1 = URL or link to open
    # $2 = "ask"  - ask first
    # $3 = "exit" - exit after opening
    #
    if [[ "$usingssh" == "true" ]]; then
        echo -e "${FColor}(The script is running over SSH)${Color_Off}"
        echo
    fi
    if [[ "$2" == "ask" || "$usingssh" == "true" ]]; then
        read -n 1 -r -p "$(echo -e "Open ${EColor}$1${Color_Off} ? (y/n) ")"; echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo
            return
        fi
    fi
    if [[ "$1" =~ ^https?:// && "$newfirefox" =~ ^[Yy]$ && "$usingssh" == "false" ]]; then
        # open urls in a new firefox window if the option is enabled
        nohup "$(command -v firefox)" --new-window "$1" > /dev/null 2>&1 &
    elif [[ "$1" == *.conf || "$1" == *.sh || "$1" == *.txt ]] && [[ "$usingssh" == "true" ]]; then
        # open these types of files in the terminal when using ssh
        # WireGuard configs, nordlist.sh, nord_favorites.txt, nord_logs.txt
        # check for default editor otherwise use nano
        if [[ -n "$VISUAL" ]]; then editor="$VISUAL"
        elif [[ -n "$EDITOR" ]]; then editor="$EDITOR"
        else editor="nano"
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
function backup_file {
    # $1 = full path and filename.  "$serversfile"  "$favoritesfile" "$nordlogfile"
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
    if [[ "$1" == "$serversfile" ]]; then
        echo -n "Server Count: "
        jq length "$1"
    elif [[ "$1" == "$favoritesfile" ]]; then
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
function quick_connect {
    # This is an alternate method of connecting to the Nord recommended server.
    # In some cases it may be faster than using "nordvpn connect".
    # Requires 'curl' and 'jq'
    # Auguss82 via github
    heading "QuickConnect"
    echo
    if [[ "$status" == "connected" && "$killswitch" == "disabled" ]]; then
        read -n 1 -r -p "Disconnect the VPN to find a nearby server? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            disconnect_vpn "force"
        fi
    fi
    if [[ "$status" != "connected" && "$killswitch" == "enabled" ]]; then
        echo -e "The VPN is $statusc with the Kill Switch ${EColor}enabled${Color_Off}."
        bestserver=""
    elif [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec"
        bestserver=""
    else
        echo "Getting the recommended server... "
        bestserver="$(timeout 5 curl --silent 'https://api.nordvpn.com/v1/servers/recommendations?limit=1' | jq --raw-output '.[0].hostname' | awk -F. '{print $1}')"
    fi
    echo
    if [[ -z $bestserver ]]; then
        echo -e "Request failed.  Trying ${LColor}nordvpn connect${Color_Off}"
        echo
        nordvpn connect
    else
        echo -e "Connect to ${LColor}$bestserver${Color_Off}"
        echo
        nordvpn connect "$bestserver"
    fi
    exit_status
    exit
}
function random_worldwide {
    # connect to a random city worldwide
    #
    create_list_country "count"
    xcountry="$rcountry"
    create_list_city "count"
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
    echo
    disconnect_vpn
    echo "Connect to $rcity $rcountry"
    echo
    nordvpn connect "$rcity"
    exit_status
    exit
}
#
# =====================================================================
#
function disconnect_warning {
    set_vars
    if [[ "$status" == "connected" ]]; then
        echo -e "${WColor}** Changing this setting will disconnect the VPN **${Color_Off}"
        echo
    fi
}
function disconnect_vpn {
    # $1 = "force" - force a disconnect
    # $2 = "check_ks" - prompt to disable the killswitch
    #
    if [[ "$disconnect" =~ ^[Yy]$ || "$1" == "force" ]]; then
        set_vars
        if [[ "$status" == "connected" ]]; then
            if [[ "$2" == "check_ks" && "$killswitch" == "enabled" ]]; then
                echo -e "${WColor}** Reminder **${Color_Off}"
                setting_change "killswitch" "back"
            fi
            echo -e "${WColor}** Disconnect **${Color_Off}"
            echo
            nordvpn disconnect
            echo
            set_vars
        fi
    fi
}
function main_disconnect {
    # disconnect option from the main menu
    heading "Disconnect"
    echo
    if [[ "$status" == "connected" && "$meshrouting" == "false" ]]; then
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
    exit_status
    exit
}
function main_header {
    # headings used for main_menu connections
    # $1 = "defaults" - force a disconnect and apply default settings
    #
    heading "$opt"
    echo
    if [[ "$1" == "defaults" ]]; then
        set_defaults
    else
        disconnect_vpn       # will only disconnect if $disconnect="y"
    fi
    echo "Connect to $opt"
    echo
}
function rate_server {
    while true
    do
        echo "How would you rate your connection quality?"
        echo -e "${DColor}Terrible${Color_Off} <_1__2__3__4__5_> ${EColor}Excellent${Color_Off}"
        echo
        read -n 1 -r -p "$(echo -e "Rating 1-5 [e${LColor}x${Color_Off}it]: ")" rating
        case "$rating" in
            [Xx] | "")
                echo -e "${DColor}(Skipped)${Color_Off}"
                break
                ;;
            [1-5])
                echo; echo
                nordvpn rate "$rating"
                break
                ;;
            *)
                echo
                echo -e "${WColor}** Please choose a number from 1 to 5 **${Color_Off}"
                echo "('Enter' or 'x' to exit)"
                ;;
        esac
        echo
    done
}
function pause_vpn {
    # disconnect the VPN, pause for a chosen number of minutes, then reconnect to any location
    #
    pcity=$(echo "$city" | tr ' ' '_' )
    pcountry=$(echo "$country" | tr ' ' '_' )
    #
    heading "Disconnect, Pause, and Reconnect" "txt" "alt"
    echo -e "$statuscl ${CIColor}$pcity${Color_Off} ${COColor}$pcountry${Color_Off} ${SVColor}$server${Color_Off}"
    echo
    echo "Reconnect to any City, Country, Server, or Group."
    echo; echo
    echo -e "Complete this command or hit 'Enter' for ${FColor}$pcity${Color_Off}"
    echo
    read -r -p "nordvpn connect " pwhere
    pwhere=${pwhere:-$pcity}
    printf '\e[A\e[K'   # erase previous line
    echo -e "${LColor}nordvpn connect $pwhere${Color_Off}"
    echo
    read -r -p "How many minutes? Hit 'Enter' for [$default_pause]: " pminutes
    pminutes=${pminutes:-$default_pause}
    # use 'bc' to handle decimal minute input
    pseconds=$( echo "scale=0; $pminutes * 60/1" | bc )
    #
    echo
    disconnect_vpn "force" "check_ks"
    reload_applet
    heading "Pause VPN"
    echo -e "$statuscl @ $(date)"
    echo
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "${WColor}Note:${Color_Off} $ks the Kill Switch is ${EColor}enabled${Color_Off}."
        echo
    fi
    echo -e "${FColor}Please do not close this window.${Color_Off}"
    echo
    echo -e "Will connect to ${EColor}$pwhere${Color_Off} after ${EColor}$pminutes${Color_Off} minutes."
    echo
    countdown_timer "$pseconds"
    heading "Reconnect"
    echo
    echo -e "${LColor}nordvpn connect $pwhere${Color_Off}"
    echo
    # shellcheck disable=SC2086 # word splitting eg. "--group P2P United_States"
    nordvpn connect $pwhere
    exit_status
    exit
}
function reload_applet {
    # reload Cinnamon Desktop applets
    #
    if [[ "$usingssh" == "true" ]]; then return; fi
    #
    if [[ "$exitappletvpn" =~ ^[Yy]$ ]]; then
        # reload 'nordlist_tray@ph202107' - changes the icon color (for connection status) immediately.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'nordlist_tray@ph202107' string:'APPLET'
    fi
    if [[ "$exitappletnm" =~ ^[Yy]$ ]]; then
        # reload 'network@cinnamon.org' - removes extra 'nordlynx' entries.
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'network@cinnamon.org' string:'APPLET'
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
function server_load {
    if [[ "$nordhost" == *"onion"* || "$meshrouting" == "true" ]]; then
        echo -e "${LColor}$nordhost${Color_Off} - Unable to check the server load."
        echo
        return
    fi
    echo -ne "$nordhost load = "
    # https://github.com/ph202107/nordlist/issues/6
    if [[ -f "$serversfile" ]]; then
        # find the "id" of the current server from the local .json
        serverid=$( jq --arg host "$nordhost" '.[] | select(.hostname == $host) | .id' "$serversfile" )
        if [[ -n "$serverid" ]]; then
            # query the api by the server id. this method downloads about 3KB instead of 20MB
            sload=$( timeout 6 curl --silent "https://api.nordvpn.com/v1/servers?limit=1&filters\[servers.id\]=$serverid" | jq '.[].load' )
        else
            # servers may be added or removed
            echo -e "${WColor}No id found for '$nordhost'${Color_Off}"
            echo "Try updating $(basename "$serversfile") (Tools - NordVPN API - All VPN Servers)"
        fi
    else
        echo -e "${WColor}$serversfile not found${Color_Off}"
        echo "Create the file at: Tools - NordVPN API - All VPN Servers"
    fi
    #
    if [[ -z $sload ]]; then
        echo "Request failed."
    elif (( sload < 40 )); then
        echo -e "${EIColor}$sload%${Color_Off}"
    elif (( sload < 70 )); then
        echo -e "${FIColor}$sload%${Color_Off}"
    else
        echo -e "${DIColor}$sload%${Color_Off}"
    fi
    echo
}
function ipinfo_curl {
    echo -n "External IP: "
    response=$(timeout 5 curl --silent --fail "https://ipinfo.io/")
    #
    # request timeout or fail, or the json is empty
    if [[ $? -ne 0 || -z "$response" ]] || ! echo "$response" | jq empty 2>/dev/null; then
        set_vars
        echo -n "Request failed"
        if [[ "$status" != "connected" && "$killswitch" == "enabled" ]]; then
            echo -ne " - $ks"
        fi
        echo; echo
        return
    fi
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
        echo -e "${SVColor}$extorg${Color_Off} ${CIColor}$extcity $extregion${Color_Off} ${COColor}$extcountry${Color_Off}"
        echo
    elif [[ -n "$extlimit" ]]; then
        echo -e "${WColor}$extlimit${Color_Off}"
        echo
    fi
}
function exit_status {
    # The commands to run before the script exits
    #
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
    if [[ "$status" == "connected" ]]; then
        if [[ "$exitkillswitch" =~ ^[Yy]$ && "$killswitch" == "disabled" ]]; then
            echo -e "${FColor}(exitkillswitch) - Always enable the Kill Switch.${Color_Off}"
            echo
            setting_enable "killswitch"
            if [[ "$exitlogo" =~ ^[Yy]$ ]]; then
                echo -e "${FColor}Updating the logo.${Color_Off}"
                clear -x
                main_logo
            fi
        fi
        if [[ "$exitping" =~ ^[Yy]$ ]]; then
            if [[ "$technology" == "openvpn" ]]; then
                echo -ne "$techpro - Ping the External IP"
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
        if [[ "$exitks_prompt" =~ ^[Yy]$ && "$killswitch" == "enabled" ]]; then
            echo -e "${WColor}** Reminder **${Color_Off}"
            setting_change "killswitch" "back"
        fi
    fi
    if [[ "$exitip" =~ ^[Yy]$ ]]; then
        ipinfo_curl
        if [[ "$status" == "connected" && "$exitping" =~ ^[Yy]$ && -n "$extip" ]]; then
            if [[ "$technology" == "openvpn" || "$meshrouting" == "true" ]]; then
                # ping the external IP when using OpenVPN or Meshnet Routing
                ping_host "$extip" "stats" "External IP"
                echo
            elif [[ "$server" == *"-"* && "$server" != *"onion"* ]]; then
                # ping both hops of Double-VPN servers when using NordLynx
                ping_host "$extip" "stats" "Double-VPN"
                echo
            fi
        fi
    fi
    date
    echo
}
#
# =====================================================================
#
function external_source {
    # Preserve your modifications when nordlist is updated by creating a
    # separate config file and sourcing it from the main script.
    #
    # This applies to all the variables and functions from the top of the
    # script up to and including function set_colors.
    # Includes the location variables, allowlist commands, the Main Menu, etc.
    #
    # Set the customization option externalsource="y".
    # Set the customization option for "nordlistbase" (or use the default).
    # Save and then run nordlist.sh
    # You will be prompted to create "nordlist_config.sh" in the "$nordlistbase"
    # directory.  Delete the existing file if you wish to recreate it.
    # Note that nordlist_config.sh does not need to be executable.
    #
    # Modify your settings and functions in nordlist_config.sh as needed.
    # Your customizations are saved there, not in nordlist.sh.
    # Unmodified functions can be completely removed from nordlist_config.sh.
    #
    # When nordlist is updated:
    # Set the customization option externalsource="y".
    # Set the customization option for "nordlistbase" if not using the default.
    # No need to recreate nordlist_config.sh or edit nordlist.sh any further.
    #
    # Settings in nordlist_config.sh override those in nordlist.sh.
    # If a setting is missing, nordlist.sh will use its default value.
    # Do not delete variables or functions from nordlist.sh.
    # Set externalsource="n" to revert to default settings.
    #
    # Customization options, variables, and functions may change with updates.
    # Compare changes using 'diff' or check GitHub commits.
    # A side-by-side diff output is available in "Settings - Script".
    # If your saved functions are affected, nordlist_config.sh will need to
    # be updated.
    #
    configfile="$nordlistbase/nordlist_config.sh"
    #
    if [[ ! -f "$configfile" ]]; then
        echo -e "${WColor}Error: $configfile does not exist.${Color_Off}"
        echo
        read -n 1 -r -p "Create the file? (y/n) "; echo
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "Set ${FColor}externalsource=\"n\"${Color_Off} to run without a config file."; echo
            exit 1
        fi
        if ! touch "$configfile"; then
            echo -e "${WColor}Error: Failed to create $configfile${Color_Off}"; echo
            exit 1
        fi
        echo -e "Created: ${EColor}$configfile${Color_Off}"
        echo
        if ! awk '/Customization/, /End Diff/ { print } /End Diff/ { exit }' "$0" > "$configfile"; then
            echo -e "${WColor}Error: Failed to populate $configfile${Color_Off}"; echo
            exit 1
        fi
        openlink "$configfile" "ask" "exit"
    fi
    if [[ ! -r "$configfile" ]]; then
        echo -e "${WColor}Error: '$configfile' is not readable.${Color_Off}"; echo
        exit 1
    fi
    # shellcheck disable=SC1090 # non-constant source
    if ! source "$configfile"; then
        echo -e "${WColor}Error: Failed to source '$configfile'.${Color_Off}"; echo
        exit 1
    fi
    set_colors  # update color scheme after source
    echo -e "${EColor}$0${Color_Off}"
    echo -e "${DColor}Settings are being sourced from:${Color_Off}"
    echo -e "${FColor}$configfile${Color_Off}"
    echo
}
function app_exists {
    # check if nordvpn and third party applications are installed
    # $1 = app to check.  use "start" to initialize the array
    #
    if [[ "$1" == "start" ]]; then
        # populate the nordlist_apps array and echo the results on script startup
        #
        declare -gA nordlist_apps   # global associative array
        #
        applications=( "wg" "jq" "curl" "figlet" "lolcat" "iperf3" "nordvpn" "unbuffer" "highlight" "speedtest-cli" )
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
        echo
        return
    fi
    # check the nordlist_apps array to confirm the program is available
    if [[ "${nordlist_apps[$1]}" == "true" ]]; then
        return 0    # success
    else
        return 1    # failure
    fi
}
function start {
    # the commands to run when the script first starts
    #
    echo
    set_colors
    # check if the script is being run in an ssh session
    if [[ -n $SSH_TTY ]]; then
        echo -e "${FColor}(The script is running over SSH)${Color_Off}"
        echo
        usingssh="true"
    else
        usingssh="false"
    fi
    # check bash version
    if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2) )); then
        echo "Bash Version $BASH_VERSION"
        echo -e "${WColor}Bash v4.2 or higher is required.${Color_Off}"; echo
        exit 1
    fi
    # create the nordlistbase directory if it doesn't exist
    mkdir -p "$nordlistbase"
    #
    # load external source
    if [[ "$externalsource" =~ ^[Yy]$ ]]; then
        external_source
    fi
    # change the terminal window titlebar text. Tested with gnome-terminal.
    if [[ -n "$titlebartext" ]]; then
        if [[ "$usingssh" == "true" ]]; then
            echo -ne "\033]2;$titlebartext $USER@$HOSTNAME\007"
        else
            echo -ne "\033]2;$titlebartext\007"
        fi
    fi
    # check installed apps
    app_exists "start"
    if app_exists "nordvpn"; then
        nordvpn --version
        echo
    else
        echo -e "${WColor}The NordVPN Linux client could not be found.${Color_Off}"
        echo "https://nordvpn.com/download/"; echo
        exit 1
    fi
    # check service
    if ! systemctl is-active --quiet nordvpnd; then
        echo -e "${WColor}nordvpnd.service is not active${Color_Off}"
        echo -e "${EColor}Starting the service... ${Color_Off}"
        echo "sudo systemctl start nordvpnd.service"
        sudo systemctl start nordvpnd.service || exit
        echo
    fi
    # check if you are logged in.  This will cause a delay every time the script starts.
    checklogin="n"
    if [[ "$checklogin" =~ ^[Yy]$ ]]; then
        login_check
    fi
    # read the favoritelist array into memory if the file exists
    # will be checked on every 'set_vars' call for the main_logo (Favorite) label
    if [[ -f "$favoritesfile" ]]; then
        readarray -t favoritelist < "$favoritesfile"
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
# Add NordVPN repository and install the nordvpn CLI:
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
