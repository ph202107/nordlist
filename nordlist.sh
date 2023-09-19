#!/bin/bash
# shellcheck disable=SC2034,SC2129,SC2154
# unused color variables, individual redirects, var assigned
#
# Tested with NordVPN Version 3.16.6 on Linux Mint 21.1
# September 19, 2023
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
# /u/pennyhoard20 on reddit
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
#       these small programs are required *
#       eg. "sudo apt install figlet lolcat curl jq"
# 4) At the terminal type "nordlist.sh"
#
# (*) The script will work without figlet and lolcat by specifying
#     "ascii_static" in "function main_logo"
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
# applet "Bash Sensors".  Screenshot:
# https://github.com/ph202107/nordlist/blob/main/screenshots
# The config is in the "Notes" at the bottom of the script.
#
# =====================================================================
# Sudo Usage
# ===========
#
#   These functions will ask for a sudo password:
#   - function restart_service
#   - function iptables_status
#   - function iptables_menu "Flush IPTables"
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
# Specify your Auto-Connect location. (Optional)
# eg. acwhere="Australia" or acwhere="Sydney"
# When obfuscate is enabled, the location must support obfuscation.
acwhere=""
#
# Specify your Custom DNS servers with a description.
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
#nordchangelog="/var/lib/dpkg/info/nordvpn.changelog"
nordchangelog="/usr/share/doc/nordvpn/changelog.gz"
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
# Specify the absolute path and filename to save a copy of the
# nordvpnd.service logs.  Create the file in: Settings - Logs
nordlogfile="/home/$USER/Downloads/nord_logs.txt"
#
# Specify the absolute path and filename to store a local list of all
# the NordVPN servers.  Avoids API server timeouts.  Create the list at:
# Tools - NordVPN API - All VPN Servers - Update List
nordserversfile="/home/$USER/Downloads/nord_allservers.txt"
#
# Specify the absolute path and filename to store a local list of your
# favorite NordVPN servers.  eg. Low ping servers or streaming servers.
# Create the list in: 'Favorites'
nordfavoritesfile="/home/$USER/Downloads/nord_favorites.txt"
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
# Ping the connected server when the script exits.  "y" or "n"
exitping="n"
#
# Query the server load when the script exits.  "y" or "n"
# Requires 'curl' and 'jq'.
exitload="n"
#
# Show your external IP address when the script exits.  "y" or "n"
# Requires 'curl'.  Connects to ipinfo.io.
exitip="n"
#
# Reload the "Bash-Sensors" applet when the script exits.  "y" or "n"
# This setting only for the Cinnamon DE with "Bash Sensors" installed.
exitapplet="n"
#
# Open http links in a new Firefox window.  "y" or "n"
# Choose "n" to use the default browser or method.
newfirefox="n"
#
# Specify the number of pings to send when pinging a destination.
pingcount="3"
#
# Set 'menuwidth' to your terminal width or lower.
# Lowering the value will compact the menus horizontally.
# Leave blank to have the menu width change with the window size.
menuwidth="80"
#
# Choosing 'Exit' in a submenu will take you to the main menu.
# Entering this value while in a submenu will return you to the default
# parent menu.  To avoid conflicts avoid using any number other than
# zero, or the letters y,n,c,e,s.    eg. upmenu="0" or upmenu="b"
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
# Routing, Analytics, KillSwitch, TPLite, Notify, AutoConnect, IPv6,
# LAN Discovery
fast2="n"
#
# Automatically change these settings which also disconnect the VPN:
# Technology, Protocol, Obfuscate
fast3="n"
#
# Automatically disconnect, change settings, and connect to these
# groups: Obfuscated, Double-VPN, Onion+VPN, P2P
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
# After choosing a country, automatically connect to the city if
# there is only one choice.
fast7="n"
#
# By default the [F] indicator will be set when any of the 'fast'
# options are enabled.
# Modify 'allfast' if you want to display the [F] indicator only when
# specific 'fast' options are enabled.
allfast=("$fast1" "$fast2" "$fast3" "$fast4" "$fast5" "$fast6" "$fast7")
#
# =====================================================================
# Visual Options
# ===============
#
# Change the main menu figlet ASCII style in "function ascii_custom"
# Change the figlet ASCII style for headings in "function heading"
# Change the text and indicator colors in "function set_colors"
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
# The Main Menu starts on line 4122 (function main_menu).
# Configure the first ten main menu items to suit your needs.
#
# Enjoy!
#
# ==End================================================================
#
function allowlist_commands {
    # Add your allowlist configuration commands here.
    # Enter one command per line.
    # allowlist_start (keep this line)
    #
    #nordvpn allowlist remove all
    #nordvpn allowlist add subnet 192.168.1.0/24
    #
    # allowlist_end (keep this line)
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
    #if [[ "$technology" == "nordlynx" ]]; then nordvpn set technology openvpn; set_vars; fi
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
    if [[ "$customdns" != "disabled" ]]; then nordvpn set dns disabled; fi
    #
    echo
}
function ascii_static {
    # This ASCII can display above the main menu if you prefer to use
    # other ASCII art. Place any ASCII art between cat << "EOF" and EOF
    # and specify ascii_static in "function main_logo".
    echo -ne "${SColor}"
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
    # This is the customized ASCII generated by figlet, displayed above the main menu.
    # Specify ascii_custom in "function main_logo".
    # Any text or variable can be used, single or multiple lines.
    if [[ "$connected" == "connected" ]]; then
        if (( "$meshrouting" )); then
            # when routing through meshnet
            figlet "Mesh Routing" | lolcat
        else
            #figlet NordVPN                         # standard font in mono
            #figlet NordVPN | lolcat -p 0.8         # standard font colorized
            #figlet -f slant NordVPN | lolcat       # slant font, colorized
            #figlet "$city" | lolcat -p 1           # display the city name, more rainbow
            figlet -f slant "$city" | lolcat       # city in slant font
            #figlet "$country" | lolcat -p 1.5      # display the country
            #figlet "$transferd" | lolcat  -p 1     # display the download statistic
        fi
    else
        figlet NordVPN                              # style when disconnected
    fi
}
function main_logo {
    # the ascii and stats shown above the main_menu and on script exit
    set_vars
    if [[ "$1" != "stats_only" ]]; then
        # Specify  ascii_static or ascii_custom on the line below.
        ascii_custom
    fi
    if (( "$meshrouting" )); then
        echo -e "$connectedcl ${SVColor}$nordhost ${IPColor}$ipaddr${Color_Off}"
    else
        echo -e "$connectedcl ${CIColor}$city ${COColor}$country ${SVColor}$server ${IPColor}$ipaddr${Color_Off}"
    fi
    echo -e "$techpro$fw$rt$an$ks$tp$ob$no$ac$ip6$mn$dns$ld$al$fst$sshi"
    echo -e "$transferc ${UPColor}$uptime${Color_Off}"
    if [[ -n $transferc ]]; then echo; fi
    # all indicators: $techpro$fw$rt$an$ks$tp$ob$no$ac$ip6$mn$dns$ld$al$fst$sshi
}
function heading {
    # $1 = heading
    # $2 = "txt" - use regular text
    # $3 = "alt" - use alternate color for regular text
    #
    clear -x
    if ! (( "$figlet_exists" )) || ! (( "$lolcat_exists" )) || [[ "$2" == "txt" ]]; then
        echo
        if [[ "$3" == "alt" ]]; then
            echo -e "${H2Color}=== $1 ===${Color_Off}"
        else
            echo -e "${H1Color}=== $1 ===${Color_Off}"
        fi
        echo
        COLUMNS="$menuwidth"
        return
    fi
    # This ASCII displays after a menu selection is made.
    # Longer names use a smaller font to prevent wrapping.
    # Assumes 80 column terminal.
    # Wide terminals can use figlet with '-t' or '-w'.
    #
    if (( ${#1} <= 14 )); then      # 14 characters or less
        figlet -f slant "$1" | lolcat -p 1000
    elif (( ${#1} <= 18 )); then    # 15 to 18 characters
        figlet -f small "$1" | lolcat -p 1000
    else                            # more than 18 characters
        echo
        echo -e "${H1Color}=== $1 ===${Color_Off}"
        echo
    fi
    COLUMNS="$menuwidth"
}
function set_colors {
    #
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
    #
    # ============== Change colors here if needed. ====================
    #
    EColor=${LGreen}        # Enabled text
    EIColor=${BGreen}       # Enabled indicator
    DColor=${LRed}          # Disabled text
    DIColor=${BRed}         # Disabled indicator
    FColor=${LYellow}       # [F]ast text
    FIColor=${BYellow}      # [F]ast indicator
    TColor=${BPurple}       # Technology and Protocol text
    TIColor=${BPurple}      # Technology and Protocol indicator
    #
    WColor=${BRed}          # Warnings, errors, disconnects
    LColor=${LCyan}         # 'Changes' lists and key info text
    SColor=${BBlue}         # Color for the ascii_static image
    H1Color=${LGreen}       # Non-figlet headings
    H2Color=${LCyan}        # Non-figlet headings alternate
    # main_logo
    CNColor=${LGreen}       # Connected status
    DNColor=${LRed}         # Disconnected status
    CIColor=${Color_Off}    # City name
    COColor=${Color_Off}    # Country name
    SVColor=${Color_Off}    # Server name
    IPColor=${Color_Off}    # IP address
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
        # the last field using <colon> as delimiter
        # some elements may have spaces eg Los Angeles, United States
        printf '%s\n' "${nstatus[@]}" | grep -i "$1" | grep -o '[^:]*$' | cut -c 2-
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
        printf '%s\n' "${nsettings[@]}" | grep -i "$1" | grep -o '[^ ]*$'
    fi
    # can also use: | awk -F' ' '{print $NF}'
    # https://stackoverflow.com/questions/22727107/how-to-find-the-last-field-using-cut
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
    nordhost=$( nstatus_search "Hostname" )
    server=$( echo "$nordhost" | cut -f1 -d'.' )
    country=$( nstatus_search "Country" )
    city=$( nstatus_search "City" )
    ipaddr=$( nstatus_search "IP:" )
    protocol2=$( nstatus_search "protocol" | tr '[:lower:]' '[:upper:]' )
    transferd=$( nstatus_search "Transfer" "line" | cut -f 2-3 -d' ' )  # download stat with units
    transferu=$( nstatus_search "Transfer" "line" | cut -f 5-6 -d' ' )  # upload stat with units
    uptime=$( nstatus_search "Uptime" "line" | cut -f 1-9 -d' ' )
    #
    # "nordvpn settings"
    # $protocol and $obfuscate are not listed when using NordLynx
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
    autoconnect=$( nsettings_search "Auto" )
    ipversion6=$( nsettings_search "IPv6" )
    meshnet=$( nsettings_search "Meshnet" | tr -d '\n' )
    customdns=$( nsettings_search "DNS" )                                       # disabled or not=disabled
    dns_servers=$( nsettings_search "DNS" "line" | tr '[:lower:]' '[:upper:]' ) # Server IPs, includes "DNS: "
    landiscovery=$( nsettings_search "Discover" )
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
    techpro="${TIColor}[$technologyd $protocold]${Color_Off}"
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
        fw="${EIColor}[FW]${Color_Off}"
        firewallc="${EColor}$firewall${Color_Off}"
    else
        fw="${DIColor}[FW]${Color_Off}"
        firewallc="${DColor}$firewall${Color_Off}"
    fi
    #
    if [[ "$routing" == "enabled" ]]; then
        rt="${EIColor}[RT]${Color_Off}"
        routingc="${EColor}$routing${Color_Off}"
    else
        rt="${DIColor}[RT]${Color_Off}"
        routingc="${DColor}$routing${Color_Off}"
    fi
    #
    if [[ "$analytics" == "enabled" ]]; then
        an="${EIColor}[AN]${Color_Off}"
    else
        an="${DIColor}[AN]${Color_Off}"
    fi
    #
    if [[ "$killswitch" == "enabled" ]]; then
        ks="${EIColor}[KS]${Color_Off}"
        killswitchc="${EColor}$killswitch${Color_Off}"
    else
        ks="${DIColor}[KS]${Color_Off}"
        killswitchc="${DColor}$killswitch${Color_Off}"
    fi
    #
    if [[ "$tplite" == "enabled" ]]; then
        tp="${EIColor}[TP]${Color_Off}"
    else
        tp="${DIColor}[TP]${Color_Off}"
    fi
    #
    if [[ "$obfuscate" == "enabled" ]]; then
        ob="${EIColor}[OB]${Color_Off}"
        obfuscatec="${EColor}$obfuscate${Color_Off}"
    else
        ob="${DIColor}[OB]${Color_Off}"
        obfuscatec="${DColor}$obfuscate${Color_Off}"
    fi
    #
    if [[ "$notify" == "enabled" ]]; then
        no="${EIColor}[NO]${Color_Off}"
    else
        no="${DIColor}[NO]${Color_Off}"
    fi
    #
    if [[ "$autoconnect" == "enabled" ]]; then
        ac="${EIColor}[AC]${Color_Off}"
    else
        ac="${DIColor}[AC]${Color_Off}"
    fi
    #
    if [[ "$ipversion6" == "enabled" ]]; then
        ip6="${EIColor}[IP6]${Color_Off}"
    else
        ip6="${DIColor}[IP6]${Color_Off}"
    fi
    #
    if [[ "$meshnet" == "enabled" ]]; then
        mn="${EIColor}[MN]${Color_Off}"
        meshnetc="${EColor}$meshnet${Color_Off}"
    else
        mn="${DIColor}[MN]${Color_Off}"
        meshnetc="${DColor}$meshnet${Color_Off}"
    fi
    #
    if [[ "$customdns" == "disabled" ]]; then # reversed
        dns="${DIColor}[DNS]${Color_Off}"
    else
        dns="${EIColor}[DNS]${Color_Off}"
    fi
    #
    if [[ "$landiscovery" == "enabled" ]]; then
        ld="${EIColor}[LD]${Color_Off}"
        landiscoveryc="${EColor}$landiscovery${Color_Off}"
    else
        ld="${DIColor}[LD]${Color_Off}"
        landiscoveryc="${DColor}$landiscovery${Color_Off}"
    fi
    #
    if [[ -n "${allowlist[*]}" ]]; then # not empty
        al="${EIColor}[AL]${Color_Off}"
    else
        al="${DIColor}[AL]${Color_Off}"
    fi
    #
    if [[ ${allfast[*]} =~ [Yy] ]]; then
        fst="${FIColor}[F]${Color_Off}"
    else
        fst=""
    fi
    #
    if [[ "$connected" == "connected" ]] && [[ "$meshnet" == "enabled" ]] && [[ "$nordhost" != *"nordvpn.com"* ]]; then
        meshrouting="1"
    else
        meshrouting=""
    fi
    #
    if (( "$usingssh" )); then
        sshi="${DIColor}[${FIColor}SSH${DIColor}]${Color_Off}"
    else
        sshi=""
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
function ipinfo_search {
    printf '%s\n' "${ipinfo[@]}" | grep -m1 -i "$1" | cut -f4 -d'"'
}
function ipinfo_curl {
    echo -n "External IP: "
    readarray -t ipinfo < <( timeout 6 curl --silent ipinfo.io )
    extip=$( ipinfo_search "ip" )
    exthost=$( ipinfo_search "hostname" )
    extorg=$( ipinfo_search "org" )
    extcity=$( ipinfo_search "city" )
    extregion=$( ipinfo_search "region" )
    extcountry=$( ipinfo_search "country" )
    extlimit=$( ipinfo_search "rate limit" )
    if [[ -n "$extip" ]]; then # not empty
        echo -e "${IPColor}$extip  $exthost${Color_Off}"
        echo -e "${SVColor}$extorg ${CIColor}$extcity $extregion ${COColor}$extcountry${Color_Off}"
        echo
    elif [[ -n "$extlimit" ]]; then
        echo -e "${WColor}$extlimit${Color_Off}"
        echo "This IP has hit the daily limit for the unauthenticated API."
        echo
    else
        set_vars
        echo -n "Request timed out"
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
            if [[ "$obfuscate" == "enabled" ]]; then
                echo -e "$ob - Unable to ping Obfuscated Servers"
            elif [[ "$technology" == "openvpn" ]]; then
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
    fi
    if [[ "$exitip" =~ ^[Yy]$ ]]; then
        ipinfo_curl
        if [[ "$connected" == "connected" ]] && [[ "$exitping" =~ ^[Yy]$ ]] && [[ "$obfuscate" != "enabled" ]] && [[ -n "$extip" ]]; then
            if [[ "$technology" == "openvpn" ]] || (( "$meshrouting" )); then
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
    # reload the "Bash Sensors" Linux Mint Cinnamon applet
    if [[ "$exitapplet" =~ ^[Yy]$ ]] && ! (( "$usingssh" )); then
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'bash-sensors@pkkk' string:'APPLET'
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
    if (( "$usingssh" )); then
        echo
        echo -e "$sshi ${FColor}The script is running over SSH${Color_Off}"
        echo
    fi
    if [[ "$2" == "ask" ]] || (( "$usingssh" )); then
        read -n 1 -r -p "$(echo -e "Open ${EColor}$1${Color_Off} ? (y/n) ")"; echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    if [[ "$1" =~ ^https?:// ]] && [[ "$newfirefox" =~ ^[Yy]$ ]] && ! (( "$usingssh" )); then
        nohup "$(command -v firefox)" --new-window "$1" > /dev/null 2>&1 &
    else
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
    # "Main" "Country" "Settings" "Group" "Tools" "Nord API" "Meshnet" "Speed Test"
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
                "Main")
                    main_menu
                    ;;
                "Country")
                    country_menu
                    ;;
                "Settings")
                    settings_menu
                    ;;
                "Group")
                    group_menu
                    ;;
                "Tools")
                    tools_menu
                    ;;
                "Nord API")
                    nordapi_menu
                    ;;
                "Meshnet")
                    meshnet_menu
                    ;;
                "Speed Test")
                    speedtest_menu
                    ;;
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
            # Shorten some names to help compact the list.
            countrylist=("${countrylist[@]/Bosnia_And_Herzegovina/Bosnia-Herz}")
            countrylist=("${countrylist[@]/Czech_Republic/Czech_Rep}")
            countrylist=("${countrylist[@]/North_Macedonia/N_Macedonia}")
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
function country_menu {
    # submenu for all available countries
    heading "Countries"
    parent="Main"
    create_list "country"
    numcountries=${#countrylist[@]}
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Countries with Obfuscation support"
        echo
    fi
    PS3=$'\n''Choose a Country: '
    select xcountry in "${countrylist[@]}"
    do
        parent_menu
        if [[ "$xcountry" == "Exit" ]]; then
            main_menu
        elif [[ "$xcountry" == "Random" ]]; then
            xcountry="$rcountry"
            city_menu
        elif (( 1 <= REPLY )) && (( REPLY <= numcountries )); then
            city_menu
        else
            invalid_option "$numcountries" "$parent"
        fi
    done
}
function city_menu {
    # all available cities in $xcountry
    # $1 = parent menu name
    if [[ -n "$1" ]]; then
        parent="$1"
    else
        parent="Country"
    fi
    if [[ "$xcountry" == "Bosnia-Herz" ]]; then xcountry="Bosnia_and_Herzegovina"
    elif [[ "$xcountry" == "Czech_Rep" ]]; then xcountry="Czech_Republic"
    elif [[ "$xcountry" == "N_Macedonia" ]]; then xcountry="North_Macedonia"
    fi
    heading "$xcountry"
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Cities in $xcountry with Obfuscation support"
        echo
    fi
    create_list "city"
    numcities=${#citylist[@]}
    if [[ "$numcities" == "2" ]] && [[ "$fast7" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast7 is enabled.${Color_Off}"
        echo
        echo "Only one available city in $xcountry."
        echo
        echo -e "Connect to ${LColor}${citylist[0]}${Color_Off}."
        echo
        disconnect_vpn
        nordvpn connect "$xcountry"
        status
        exit
    fi
    PS3=$'\n''Connect to City: '
    select xcity in "${citylist[@]}"
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
                if (( 1 <= REPLY )) && (( REPLY <= numcities )); then
                    heading "$xcity"
                    disconnect_vpn
                    echo "Connect to $xcity $xcountry"
                    echo
                    nordvpn connect "$xcity"
                    status
                    exit
                else
                    invalid_option "$numcities" "$parent"
                fi
                ;;
        esac
    done
}
function city_count {
    # list all the available cities by country and alphabetically
    allcities=()
    create_list "country" "count"
    heading "Countries" "txt"
    printf '%s\n' "${countrylist[@]}"
    heading "Cities by Country" "txt"
    for xcountry in "${countrylist[@]}"
    do
        echo "$xcountry"
        create_list "city" "count"
        for city in "${citylist[@]}"
        do
            echo "    $city"
            allcities+=( "$city $xcountry" )
        done
        echo
    done
    heading "Cities Alphabetical" "txt"
    printf '%s\n' "${allcities[@]}" | sort
    echo
    echo "====================="
    echo "Total Countries = ${#countrylist[@]}"
    echo "Total Cities = ${#allcities[@]}"
    echo "====================="
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec."
        echo "These locations have Obfuscation support."
    else
        echo "Dubai United_Arab_Emirates = Obfuscated_Servers only."
    fi
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
    echo "A list of servers can be found in:"
    echo "Settings - Tools - NordVPN API"
    echo
    echo -e "${FColor}(Leave blank to quit)${Color_Off}"
    echo
    read -r -p "Enter the server name (eg. us9364): " servername
    if [[ -z $servername ]]; then
        echo -e "${DColor}(Skipped)${Color_Off}"
        echo
        return
    elif [[ "$servername" == *"socks"* ]]; then
        echo
        echo -e "${WColor}Unable to connect to SOCKS servers${Color_Off}"
        echo
        return
    elif [[ "$servername" == *"nord"* ]]; then
        servername=$( echo "$servername" | cut -f1 -d'.' )
    fi
    disconnect_vpn
    echo "Connect to $servername"
    echo
    nordvpn connect "$servername"
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
    if [[ "$killswitch" == "disabled" ]]; then
        if [[ "$fast5" =~ ^[Yy]$ ]]; then
            echo -e "${FColor}[F]ast5 is enabled.  Enabling the Kill Switch.${Color_Off}"
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
    fi
}
function group_connect {
    # $1 = Nord group name
    #
    parent="Group"
    location=""
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
            echo "Double VPN is a privacy solution that sends your internet"
            echo "traffic through two VPN servers, encrypting it twice."
            location="$dblwhere"
            ;;
        "Onion_Over_VPN")
            heading "Onion+VPN"
            echo "Onion over VPN is a privacy solution that sends your "
            echo "internet traffic through a VPN server and then"
            echo "through the Onion network."
            ;;
        "P2P")
            heading "Peer to Peer"
            echo "Peer to Peer - sharing information and resources directly"
            echo "without relying on a dedicated central server."
            location="$p2pwhere"
            ;;
    esac
    echo
    echo -e "Current settings: $techpro$fw$ks$ob"
    echo
    echo "To connect to the $1 group the following"
    echo "changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    if [[ "$1" == "Obfuscated_Servers" ]]; then
        echo "Set Technology to OpenVPN."
        echo "Choose the Protocol."
        echo "Set Obfuscate to enabled."
    else
        echo "Choose the Technology & Protocol."
        echo "Set Obfuscate to disabled."
    fi
    echo "Enable the Kill Switch (choice)."
    echo -e "Connect to the $1 group ${EColor}$location${Color_Off}"
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    elif [[ "$1" == "Onion_Over_VPN" ]]; then
        echo
        read -n 1 -r -p "Proceed? (y/n) "; echo
    else
        echo -e "${LColor}(Type ${FIColor}S${LColor} to specify a location)${Color_Off}"
        echo
        read -n 1 -r -p "Proceed? (y/n/S) "; echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            heading "Set Location" "txt" "alt"
            if [[ -n $location ]]; then
                echo -e "Default location ${EColor}$location${Color_Off} will be ignored."
                echo
            fi
            echo "The location must support $1."
            echo "Leave blank to have the app choose automatically."
            echo
            echo -e "${FColor}(Enter '$upmenu' to return to the $parent menu)${Color_Off}"
            echo
            read -r -p "Enter the $1 location: " location
            REPLY="$location"
            parent_menu
            REPLY="y"
        fi
    fi
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnect_vpn "force"
        if [[ "$1" == "Obfuscated_Servers" ]]; then
            if [[ "$technology" == "nordlynx" ]]; then
                nordvpn set technology openvpn; wait
                echo
            fi
            protocol_ask
            if [[ "$obfuscate" == "disabled" ]]; then
                nordvpn set obfuscate enabled; wait
                echo
            fi
        else
            technology_setting "back"
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
                echo
            fi
        fi
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
        echo "OpenVPN is an open-source VPN protocol and is required to"
        echo " use Obfuscated servers and to use TCP."
        echo "NordLynx is built around the WireGuard VPN protocol"
        echo " and may be faster with less overhead."
        echo
    fi
    echo -e "Currently using $technologydc."
    echo
    if [[ "$fast3" =~ ^[Yy]$ ]] && [[ "$1" != "back" ]]; then
        echo -e "${FColor}[F]ast3 is enabled.  Changing the Technology.${Color_Off}"
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
        else
            nordvpn set technology openvpn; wait
            echo
            protocol_ask
        fi
    else
        echo
        echo -e "Continue to use $technologydc."
        set_vars
        if [[ "$technology" == "openvpn" ]] && [[ "$connected" != "connected" ]]; then
            echo
            protocol_ask
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
        echo -e "${FColor}[F]ast3 is enabled.  Changing the Protocol.${Color_Off}"
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
        echo -e "${FColor}[F]ast6 is enabled.  Always choose $fast6p.${Color_Off}"
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
    parent="Settings"
    chgloc=""
    case "$1" in
        "firewall")
            chgname="the Firewall"; chgvar="$firewall"; chgind="$fw"
            ;;
        "routing")
            chgname="Routing"; chgvar="$routing"; chgind="$rt"
            ;;
        "analytics")
            chgname="Analytics"; chgvar="$analytics"; chgind="$an"
            ;;
        "killswitch")
            chgname="the Kill Switch"; chgvar="$killswitch"; chgind="$ks"
            ;;
        "threatprotectionlite")
            chgname="Threat Protection Lite"; chgvar="$tplite"; chgind="$tp"
            ;;
        "notify")
            chgname="Notify"; chgvar="$notify"; chgind="$no"
            ;;
        "autoconnect")
            chgname="Auto-Connect"; chgvar="$autoconnect"; chgind="$ac"; chgloc="$acwhere"
            ;;
        "ipv6")
            chgname="IPv6"; chgvar="$ipversion6"; chgind="$ip6"
            ;;
        "meshnet")
            chgname="Meshnet"; chgvar="$meshnet"; chgind="$mn"
            ;;
        "lan-discovery")
            chgname="LAN Discovery"; chgvar="$landiscovery"; chgind="$ld"
            ;;
        *)
            echo; echo -e "${WColor}'$1' not defined${Color_Off}"; echo
            return
            ;;
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
        echo -e "${FColor}[F]ast2 is enabled.  Changing the setting.${Color_Off}"
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
                    echo
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
    echo -e "${FColor}This setting must be enabled.${Color_Off}"
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
    echo "Threat Protection Lite is a feature protecting you"
    echo "from ads, unsafe connections, and malicious sites."
    echo "Previously known as 'CyberSec'."
    echo
    echo -e "Enabling TPLite disables Custom DNS $dns"
    if [[ "$customdns" != "disabled" ]]; then
        echo "Current $dns_servers"
    fi
    echo
    change_setting "threatprotectionlite"
}
function notify_setting {
    heading "Notify"
    echo
    echo "Send OS notifications when the VPN status changes"
    echo "and on Meshnet file transfer events."
    echo
    change_setting "notify"
}
function autoconnect_setting {
    heading "AutoConnect"
    echo "Automatically connect to the VPN on startup."
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob When obfuscate is enabled, the Auto-Connect"
        echo "     location must support obfuscation."
        echo
    fi
    if [[ "$autoconnect" == "disabled" ]] && [[ -n $acwhere ]]; then
        echo -e "Auto-Connect location: ${LColor}$acwhere${Color_Off}"
        echo
    fi
    change_setting "autoconnect"
}
function ipv6_setting {
    heading "IPv6"
    echo "Enable or disable NordVPN IPv6 support."
    echo
    echo "Also refer to: https://support.nordvpn.com/1047409212"
    echo
    change_setting "ipv6"
}
function landiscovery_setting {
    heading "LAN Discovery"
    echo
    echo "Access your local network while connected to a VPN, routing traffic"
    echo "through a Meshnet device, or with the Kill Switch enabled."
    echo
    echo "Automatically allow traffic from these subnets:"
    echo "192.168.0.0/16  172.16.0.0/12  10.0.0.0/8  169.254.0.0/16"
    echo
    if [[ -n "${allowlist[*]}" ]]; then
        echo -e "$al Note: Enabling local network discovery will remove any"
        echo "manually added private subnets from the allowlist."
        echo
    fi
    change_setting "lan-discovery"
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
        echo -e "${FColor}[F]ast3 is enabled.  Changing the setting.${Color_Off}"
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
    submshare=("List Transfers" "List Files" "Send" "Accept" "Auto-Accept" "Cancel" "Notify" "Online Peers"  "Exit")
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "Enter the recipient public_key, hostname, or IP: " meshwhere
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo "Enter 'enable' or 'disable' and the public_key, hostname, or IP"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                parent="Meshnet"
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
    submesh=("Enable/Disable" "Peer List" "Peer Refresh" "Peer Online" "Peer Filter" "Peer Remove" "Peer Incoming" "Peer Routing" "Peer Local" "Peer FileShare" "Peer Connect" "Invitations" "File Sharing" "Speed Tests" "Restart Service" "Support" "Exit")
    select mesh in "${submesh[@]}"
    do
        parent_menu
        case $mesh in
            "Enable/Disable")
                clear -x
                echo
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
                echo
                echo "Enter the public_key, hostname, or IP address."
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo "Enter 'allow' or 'deny' and the public_key, hostname, or IP"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo "Enter 'allow' or 'deny' and the public_key, hostname, or IP"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo "Enter 'allow' or 'deny' and the public_key, hostname, or IP"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                echo "Enter 'allow' or 'deny' and the public_key, hostname, or IP"
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
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
                echo
                if [[ "$technology" != "nordlynx" ]]; then
                    echo -e "Currently using $technologydc."
                    echo
                fi
                echo "Enter the public_key, hostname, or IP address."
                echo
                echo -e "${FColor}(Leave blank to quit)${Color_Off}"
                echo
                read -r -p "nordvpn meshnet peer connect "
                if [[ -n $REPLY ]]; then
                    echo
                    nordvpn meshnet peer connect "$REPLY"
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
                read -n 1 -r -p "Disconnect the VPN and restart the nordvpn service? (y/n) "; echo
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [[ "$killswitch" == "enabled" ]]; then
                        change_setting "killswitch" "back"
                    fi
                    disconnect_vpn "force"
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
    echo "You can specify your own Custom DNS servers instead."
    echo
    echo -e "Enabling Custom DNS disables TPLite $tp"
    echo
    if [[ "$customdns" == "disabled" ]]; then
        echo -e "$dns Custom DNS is ${DColor}disabled${Color_Off}."
    else
        echo -e "$dns Custom DNS is ${EColor}enabled${Color_Off}."
        echo "Current $dns_servers"
    fi
    echo
    PS3=$'\n''Choose an option: '
    # Note submcdns[@] - new entries should keep the same format for the "Test Servers" option
    # eg Name<space>DNS1<space>DNS2
    submcdns=("Nord 103.86.96.100 103.86.99.100" "Nord-TPLite 103.86.96.96 103.86.99.99" "OpenDNS 208.67.220.220 208.67.222.222" "CB-Security 185.228.168.9 185.228.169.9" "AdGuard 94.140.14.14 94.140.15.15" "Quad9 9.9.9.9 149.112.112.11" "Cloudflare 1.0.0.1 1.1.1.1" "Google 8.8.4.4 8.8.8.8" "Specify or Default" "Disable Custom DNS" "Flush DNS Cache" "Test Servers" "Exit")
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
                read -r -p "Up to 3 DNS server IPs: " dns3srvrs
                dns3srvrs=${dns3srvrs:-$default_dns}
                tplite_disable
                # shellcheck disable=SC2086 # word splitting eg. "1.1.1.1 1.0.0.1 8.8.8.8"
                nordvpn set dns $dns3srvrs
                ;;
            "Disable Custom DNS")
                echo
                nordvpn set dns disabled; wait
                echo
                ;;
            "Flush DNS Cache")
                # https://devconnected.com/how-to-flush-dns-cache-on-linux/
                echo
                if (( "$systemdresolve_exists" )); then
                    sudo echo
                    sudo systemd-resolve --statistics | grep "Current Cache Size"
                    echo -e "${WColor}  == Flush ==${Color_Off}"
                    sudo systemd-resolve --flush-caches
                    sudo systemd-resolve --statistics | grep "Current Cache Size"
                else
                    echo -e "${WColor}systemd-resolve not found${Color_Off}"
                    echo "For alternate methods see:"
                    echo " https://devconnected.com/how-to-flush-dns-cache-on-linux/ "
                    # sudo lsof -i :53 -S
                fi
                echo
                ;;
            "Test Servers")
                echo
                echo "Specify a Hostname to lookup. "
                read -r -p "Hit 'Enter' for [$default_dnshost]: " testhost
                testhost=${testhost:-$default_dnshost}
                echo
                echo -e "${EColor}dig @<DNS> $testhost${Color_Off}"
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
        echo -e "local network discovery is enabled."
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
    if (( "$highlight_exists" )); then
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
    echo "Services - NordVPN - Access Token - Generate New Token"
    echo
    openlink "https://my.nordaccount.com/" "ask"
    echo
    echo -e "${FColor}(Leave blank to quit)${Color_Off}"
    echo
    read -r -p "Enter the login token: " logintoken
    if [[ -z $logintoken ]]; then
        echo -e "${DColor}(Skipped)${Color_Off}"
    else
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
        echo "nordvpn logout --persist-token"
        echo
        nordvpn logout --persist-token
    else
        echo "nordvpn logout"
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
    submacct=("Login Check" "Login (browser)" "Login (token)" "Login (no GUI)" "Logout" "Account Info" "Register" "Nord Version" "Changelog" "Nord Manual" "Support" "NordAccount" "Exit")
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
            "Nord Version")
                echo
                nordvpn --version
                ;;
            "Changelog")
                #zcat "$nordchangelog"
                #zless +G "$nordchangelog"
                # version numbers are not in order (latest release != last entry)
                echo
                zless -p"$( nordvpn --version | cut -f3 -d' ' )" "$nordchangelog"
                openlink "https://nordvpn.com/blog/nordvpn-linux-release-notes" "ask"
                # https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/
                ;;
            "Nord Manual")
                echo
                man nordvpn
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
                echo -e "${H2Color}Warrant Canary (bottom of page)${Color_Off}"
                echo "https://nordvpn.com/security-efforts/"
                echo
                echo -e "${H2Color}Bug Bounty${Color_Off}"
                echo "https://hackerone.com/nordsecurity?type=team"
                echo
                ;;
            "NordAccount")
                echo
                openlink "https://my.nordaccount.com/" "ask"
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
        echo "Restart nordvpn services."
    fi
    echo -e "${WColor}"
    echo "Send commands:"
    echo "sudo systemctl restart nordvpnd.service"
    echo "sudo systemctl restart nordvpn.service"
    echo -e "${Color_Off}"
    if [[ "$1" == "back" ]]; then
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "; echo
        echo
    fi
    parent_menu "$1"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl restart nordvpnd.service
        sudo systemctl restart nordvpn.service
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
}
function reset_app {
    heading "Reset Nord"
    parent="Settings"
    echo
    echo "Reset the NordVPN app to default settings."
    echo "Requires NordVPN username/password to reconnect."
    echo -e "${WColor}"
    echo "Send commands:"
    echo "nordvpn set killswitch disabled"
    echo "nordvpn disconnect"
    echo "nordvpn logout"
    echo "nordvpn allowlist remove all"
    echo "nordvpn set defaults"
    echo "Restart nordvpn services"
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
        nordvpn login
        echo
        read -n 1 -r -p "Press any key after login is complete... "; echo
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
    echo -e "$ld LAN Discovery is $landiscoveryc."
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
function iptables_menu {
    heading "IPTables"
    parent="Settings"
    echo "Flushing the IPTables may help resolve problems enabling or"
    echo "disabling the KillSwitch or with other connection issues."
    echo
    echo -e "${WColor}** WARNING **${Color_Off}"
    echo "  - This will CLEAR all of your Firewall rules"
    echo "  - Review 'function iptables_menu' before use"
    echo "  - Commands require 'sudo'"
    echo
    PS3=$'\n''Choose an option: '
    submipt=("View IPTables" "Firewall" "Routing" "KillSwitch" "Meshnet" "LAN Discovery" "Allowlist" "Flush IPTables" "Restart Service" "Ping Google" "Disconnect" "Exit")
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
            "LAN Discovery")
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
                echo
                echo -e "${WColor}Flush the IPTables and clear all of your Firewall rules.${Color_Off}"
                echo
                read -n 1 -r -p "Proceed? (y/n) "; echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo
                    echo -e "${LColor}IPTables Before:${Color_Off}"
                    sudo iptables -S
                    echo
                    echo -e "${WColor}Flushing the IPTables${Color_Off}"
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
                    echo
                    echo -e "${EColor}IPTables After:${Color_Off}"
                    sudo iptables -S
                    echo
                else
                    echo
                    echo "No changes made."
                    echo
                fi
                ;;
            "Restart Service")
                echo
                echo -e "${WColor}Disconnect the VPN and restart nordvpn service.${Color_Off}"
                echo "Restarting the service should recreate the Nord iptables rules."
                echo
                read -n 1 -r -p "Proceed? (y/n) "; echo
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
    echo
    echo -e "Generate log file: ${LColor}$nordlogfile${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        journalctl -u nordvpnd > "$nordlogfile"
        openlink "$nordlogfile" "ask"
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
    if [[ "$nordhost" == *"onion"* ]] || (( "$meshrouting" )); then
        echo -e "${LColor}$nordhost${Color_Off} - Unable to check the server load."
        echo
        return
    fi
    echo -ne "$nordhost load = "
    sload=$(timeout 10 curl --silent https://api.nordvpn.com/server/stats/"$nordhost" | jq .percent)
    if [[ -z $sload ]]; then
        echo "Request timed out."
    elif (( sload <= 30 )); then
        echo -e "${EIColor}$sload%${Color_Off}"
    elif (( sload <= 60 )); then
        echo -e "${FIColor}$sload%${Color_Off}"
    else
        echo -e "${DIColor}$sload%${Color_Off}"
    fi
    echo
}
function allservers_menu {
    # API timeout/rejection error "parse error: Invalid numeric literal at line 1, column 6"
    # If you get this error try again later.
    heading "All Servers"
    parent="Nord API"
    if (( ${#allnordservers[@]} == 0 )); then
        if [[ -f "$nordserversfile" ]]; then
            echo -e "${EColor}Server List: ${LColor}$nordserversfile${Color_Off}"
            head -n 1 "$nordserversfile"
            readarray -t allnordservers < <( tail -n +4 "$nordserversfile" )
        else
            echo "Retrieving the list of NordVPN servers..."
            echo "Choose 'Update List' to save a local copy of the server list."
            echo
            readarray -t allnordservers < <( curl --silent https://api.nordvpn.com/server | jq --raw-output '.[].domain' | sort --version-sort )
        fi
    fi
    echo "Server Count: ${#allnordservers[@]}"
    echo
    PS3=$'\n''Choose an option: '
    COLUMNS="$menuwidth"
    submallvpn=( "List All Servers" "Double-VPN Servers" "Onion Servers" "SOCKS Servers" "Search" "Connect" "Update List" )
    if [[ -f "$nordserversfile" ]]; then
        submallvpn+=( "Edit File" )
    fi
    submallvpn+=( "Exit" )
    select avpn in "${submallvpn[@]}"
    do
        parent_menu
        case $avpn in
            "List All Servers")
                heading "All the VPN Servers" "txt"
                printf '%s\n' "${allnordservers[@]}"
                echo
                echo "All Servers: ${#allnordservers[@]}"
                echo
                ;;
            "Double-VPN Servers")
                heading "Double-VPN Servers" "txt"
                printf '%s\n' "${allnordservers[@]}" | grep "-" | grep -i -v -E "socks|onion|napps-6"
                echo
                # work in progress
                echo "Double-VPN Servers: $( printf '%s\n' "${allnordservers[@]}" | grep "-" | grep -i -v -E "socks|onion|napps-6" -c )"
                echo
                ;;
            "Onion Servers")
                heading "Onion Servers" "txt"
                printf '%s\n' "${allnordservers[@]}" | grep -i "onion"
                echo
                echo "Onion Servers: $( printf '%s\n' "${allnordservers[@]}" | grep -c -i "onion" )"
                echo
                ;;
            "SOCKS Servers")
                heading "SOCKS Servers" "txt"
                printf '%s\n' "${allnordservers[@]}" | grep -i "socks"
                echo
                echo "SOCKS Servers: $( printf '%s\n' "${allnordservers[@]}" | grep -c -i "socks" )"
                echo
                echo "Proxy names and locations are available online:"
                echo
                openlink "https://support.nordvpn.com/Connectivity/Proxy/1087802472/Proxy-setup-on-qBittorrent.htm" "ask"
                echo
                ;;
            "Search")
                echo
                read -r -p "Enter search term: " allvpnsearch
                echo
                heading "Search for '$allvpnsearch'" "txt"
                printf '%s\n' "${allnordservers[@]}" | grep -i "$allvpnsearch"
                echo
                echo "'$allvpnsearch' Count: $( printf '%s\n' "${allnordservers[@]}" | grep -c -i "$allvpnsearch" )"
                echo
                ;;
            "Connect")
                host_connect
                ;;
            "Update List")
                echo
                if [[ -f "$nordserversfile" ]]; then
                    echo -e "${EColor}Server List: ${LColor}$nordserversfile${Color_Off}"
                    head -n 2 "$nordserversfile"
                    echo
                    read -n 1 -r -p "Update the list? (y/n) "; echo
                else
                    echo -e "${WColor}$nordserversfile does not exist.${Color_Off}"
                    echo
                    read -n 1 -r -p "Create the file? (y/n) "; echo
                fi
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [[ -f "$nordserversfile" ]]; then
                        echo "Retrieving the list of NordVPN servers..."
                        echo
                        readarray -t allnordservers < <( curl --silent https://api.nordvpn.com/server | jq --raw-output '.[].domain' | sort --version-sort )
                    fi
                    if (( ${#allnordservers[@]} < 1000 )); then
                        echo
                        echo -e "${WColor}Server list is empty. Parse Error? Try again later.${Color_Off}"
                        echo
                        if [[ -f "$nordserversfile" ]]; then
                            # rebuild array if it was blanked out on retrieval attempt
                            readarray -t allnordservers < <( tail -n +4 "$nordserversfile" )
                        fi
                    else
                        echo "Retrieved on: $( date )" > "$nordserversfile"
                        echo "Server Count: ${#allnordservers[@]}" >> "$nordserversfile"
                        echo >> "$nordserversfile"
                        printf '%s\n' "${allnordservers[@]}" >> "$nordserversfile"
                        echo -e "Saved as ${LColor}$nordserversfile${Color_Off}"
                        head -n 2 "$nordserversfile"
                        echo
                    fi
                fi
                ;;
            "Edit File")
                echo
                openlink "$nordserversfile" "ask" "exit"
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
function nordapi_menu {
    # Commands copied from:
    # https://sleeplessbeastie.eu/2019/02/18/how-to-use-public-nordvpn-api/
    heading "Nord API"
    parent="Tools"
    echo "Query the NordVPN Public API.  Requires 'curl' and 'jq'"
    echo "Commands may take a few seconds to complete."
    echo "Rate-limiting by the server may result in a Parse error."
    echo
    if [[ "$connected" == "connected" ]]; then
        echo -e "Connected to: ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    PS3=$'\n''API Call: '
    COLUMNS="$menuwidth"
    submapi=("Host Server Load" "Host Server Info" "Top 15 Recommended" "Top 15 By Country" "#Servers per Country" "All VPN Servers" "All Cities" "Change Host" "Connect" "Exit")
    select napi in "${submapi[@]}"
    do
        parent_menu
        case $napi in
            "Host Server Load")
                heading "Current $nordhost Load" "txt" "alt"
                server_load
                ;;
            "Host Server Info")
                heading "Server $nordhost Info" "txt" "alt"
                curl --silent https://api.nordvpn.com/server | jq '.[] | select(.domain == "'"$nordhost"'")'
                ;;
            "Top 15 Recommended")
                heading "Top 15 Recommended" "txt" "alt"
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations" | jq --raw-output 'limit(15;.[]) | "  Server: \(.name)\nHostname: \(.hostname)\nLocation: \(.locations[0].country.name) - \(.locations[0].country.city.name)\n    Load: \(.load)\n"'
                ;;
            "Top 15 By Country")
                heading "Top 15 by Country Code" "txt" "alt"
                curl --silent "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | [.id, .name] | @tsv'
                echo
                read -r -p "Enter the Country Code number: " ccode
                echo
                echo -e "${H2Color}SERVER: ${H1Color}%LOAD${Color_Off}"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=$ccode&\[servers_groups\]\[identifier\]=legacy_standard" | jq --raw-output --slurp ' .[] | sort_by(.load) | limit(15;.[]) | [.hostname, .load] | "\(.[0]): \(.[1])"'
                echo
                ;;
            "#Servers per Country")
                heading "Number of Servers per Country" "txt" "alt"
                curl --silent https://api.nordvpn.com/server | jq --raw-output '. as $parent | [.[].country] | sort | unique | .[] as $country | ($parent | map(select(.country == $country)) | length) as $count |  [$country, $count] |  "\(.[0]): \(.[1])"'
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
function wireguard_gen {
    # Based on Tomba's NordLynx2WireGuard script
    # https://github.com/TomBayne/tombas-script-repo
    heading "WireGuard"
    parent="Tools"
    echo "Generate a WireGuard config file from your currently active"
    echo "NordLynx connection.  Requires WireGuard/WireGuard-Tools."
    echo "Commands require sudo.  Note: Keep your Private Key secure."
    echo
    set_vars
    wgcity=$( echo "$city" | tr -d ' ' )
    wgconfig="${wgcity}_${server}.conf"     # Filename
    wgfull="${wgdir}/${wgconfig}"           # Full path and filename
    #
    if ! (( "$wg_exists" )); then
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
    echo
    parent_menu
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #
        address=$(ip route get 8.8.8.8 | cut -f7 -d' ' | tr -d '\n')
        #listenport=$(sudo wg showconf nordlynx | grep 'ListenPort = .*')
        privatekey=$(sudo wg showconf nordlynx | grep 'PrivateKey = .*')
        publickey=$(sudo wg showconf nordlynx | grep 'PublicKey = .*')
        endpoint=$(sudo wg showconf nordlynx | grep 'Endpoint = .*')
        #
        echo "# $server.nordvpn.com" > "$wgfull"
        echo "# $city $country" >> "$wgfull"
        echo "# Server IP: $ipaddr" >> "$wgfull"
        echo >> "$wgfull"
        echo "[Interface]" >> "$wgfull"
        echo "Address = ${address}/32" >> "$wgfull"
        echo "${privatekey}" >> "$wgfull"
        echo "DNS = 103.86.96.100, 103.86.99.100" >> "$wgfull"  # Regular DNS
        # echo "DNS = 103.86.96.96, 103.86.99.99" >> "$wgfull"  # Threat Protection Lite DNS
        echo >> "$wgfull"
        echo "[Peer]" >> "$wgfull"
        echo "${endpoint}" >> "$wgfull"
        echo "${publickey}" >> "$wgfull"
        echo "AllowedIPs = 0.0.0.0/0, ::/0" >> "$wgfull"
        echo "PersistentKeepalive = 25" >> "$wgfull"
        echo
        echo -e "${EColor}Completed \u2705${Color_Off}" # unicode checkmark
        echo
        echo -e "Saved as ${LColor}$wgfull${Color_Off}"
        echo
        if (( "$highlight_exists" )); then
            highlight -O xterm256 "$wgfull"
        else
            cat "$wgfull"
        fi
        echo
        openlink "$wgfull" "ask"
    fi
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
    if ! (( "$iperf3_exists" )); then
        echo -e "${WColor}iperf3 could not be found.${Color_Off}"
        echo "Please install iperf3.  https://iperf.fr/ "
        echo "eg. 'sudo apt install iperf3'"
        echo
        return
    fi
    echo "Enter the remote server IP address or hostname."
    echo "Can leave blank if starting a server."
    echo
    read -r -p "iperf3 Server: " iperfserver
    echo
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
    if ! (( "$speedtestcli_exists" )); then
        echo -e "${WColor}speedtest-cli could not be found.${Color_Off}"
        echo "Please install speedtest-cli"
        echo "eg. 'sudo apt install speedtest-cli'"
        echo
    fi
    PS3=$'\n''Select a test: '
    submspeed=( "Download & Upload" "Download Only" "Upload Only" "Latency & Load" "iperf3" "speedtest.net"  "speedof.me" "fast.com" "linode.com" "digitalocean.com" "nperf.com" "Exit" )
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
                    if [[ "$obfuscate" == "enabled" ]]; then
                        echo -e "$ob - Unable to ping Obfuscated Servers"
                        echo
                    else
                        echo -e "$technologydc - Server IP will not respond to ping."
                        echo "Attempt to ping your external IP instead."
                        echo
                        ipinfo_curl
                        if [[ -n "$extip" ]]; then
                            ping_host "$extip" "show"
                        fi
                    fi
                else
                    ping_host "$nordhost" "show"
                fi
                server_load
                ;;
            "iperf3")
                speedtest_iperf3
                ;;
            "speedtest.net")
                openlink "http://www.speedtest.net/"
                ;;
            "speedof.me")
                openlink "https://speedof.me/"
                ;;
            "fast.com")
                openlink "https://fast.com"
                ;;
            "linode.com")
                openlink "https://www.linode.com/speed-test/"
                ;;
            "digitalocean.com")
                openlink "http://speedtest-blr1.digitalocean.com/"
                ;;
            "nperf.com")
                openlink "https://www.nperf.com/en/"
                ;;
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
    submtools=( "NordVPN API" "Speed Tests" "WireGuard" "External IP" "Server Load" "Rate VPN Server" "Ping VPN Server" "Ping Test" "My TraceRoute" "ipleak cli" "ipleak.net" "dnsleaktest.com" "dnscheck.tools" "test-ipv6.com" "ipx.ac" "ipinfo.io" "ip2location.io" "ipaddress.my" "locatejs.com" "browserleaks.com" "bash.ws" "Change Host" "World Map" "Outage Map" "Down Detector" "Exit" )
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
            "ipleak.net")
                openlink "https://ipleak.net/"
                ;;
            "dnsleaktest.com")
                openlink "https://dnsleaktest.com/"
                ;;
            "dnscheck.tools")
                openlink "https://dnscheck.tools/"
                ;;
            "test-ipv6.com")
                openlink "https://test-ipv6.com/"
                ;;
            "ipx.ac")
                openlink "https://ipx.ac/"
                ;;
            "ipinfo.io")
                openlink "https://ipinfo.io/"
                ;;
            "ip2location.io")
                openlink "https://www.ip2location.io/"
                ;;
            "ipaddress.my")
                openlink "https://www.ipaddress.my/"
                ;;
            "locatejs.com")
                openlink "https://locatejs.com/"
                ;;
            "browserleaks.com")
                openlink "https://browserleaks.com/"
                ;;
            "bash.ws")
                openlink "https://bash.ws/"
                ;;
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
    endline=$(grep -m1 -n "End" "$0" | cut -f1 -d':')
    numlines=$(( endline - startline + 2 ))
    if (( "$highlight_exists" )); then
        highlight -l -O xterm256 "$0" | head -n "$endline" | tail -n "$numlines"
    else
        cat -n "$0" | head -n "$endline" | tail -n "$numlines"
    fi
    echo
    echo "Need to edit the script to change these settings."
    echo
    openlink "$0" "ask" "exit"
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
        echo -e "Request timed out. Using ${EColor}nordvpn connect${Color_Off}"
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
    numgroups=${#grouplist[@]}
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
        elif (( 1 <= REPLY )) && (( REPLY <= numgroups )); then
            heading "$xgroup"
            disconnect_vpn
            echo "Connect to the $xgroup group."
            echo
            nordvpn connect --group "$xgroup"
            status
            exit
        else
            invalid_option "$numgroups" "$parent"
        fi
    done
}
function favorites_menu {
    # $1 = parent menu name
    heading "Favorites"
    if [[ -n "$1" ]]; then
        parent="$1"
    else
        parent="Main"
    fi
    main_logo "stats_only"
    echo "Keep track of your favorite individual servers by adding them to"
    echo "this list. For example low ping servers or streaming servers."
    echo
    if [[ -f "$nordfavoritesfile" ]]; then
        # trim spaces and remove empty lines
        # https://stackoverflow.com/questions/16414410/delete-empty-lines-using-sed/24957725#24957725
        sed -i 's/^ *//; s/ *$//; /^$/d' "$nordfavoritesfile"
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
    rfavorite=$( printf '%s\n' "${favoritelist[ RANDOM % ${#favoritelist[@]} ]}" )
    favoritelist+=( "Random" )
    if [[ "$connected" == "connected" ]]; then
        if grep -q "$server" "$nordfavoritesfile"; then
            echo -e "The Current Server is in the list:  ${FColor}$( grep "$server" "$nordfavoritesfile" )${Color_Off}"
            echo
        else
            favoritelist+=( "Add Current Server" )
        fi
    fi
    favoritelist+=( "Add Server" "Edit File" "Exit" )
    numfavorites=${#favoritelist[@]}
    PS3=$'\n''Connect to Server: '
    COLUMNS="$menuwidth"
    select xfavorite in "${favoritelist[@]}"
    do
        parent_menu
        case $xfavorite in
            "Exit")
                main_menu
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
                read -r -p "Enter the server name or hit 'Enter' for default: " favadd
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
                if (( 1 <= REPLY )) && (( REPLY <= numfavorites )); then
                    # to handle more than one <underscore> in the entry
                    # reverse the text so the first field is the server and the rest is heading
                    heading "$( echo "$xfavorite" | rev | cut -f2- -d'_' | rev )"
                    disconnect_vpn
                    echo "Connect to $xfavorite"
                    echo
                    nordvpn connect "$( echo "$xfavorite" | rev | cut -f1 -d'_' | rev )"
                    status
                    exit
                else
                    invalid_option "$numfavorites" "$parent"
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
    submgroups=("All_Groups" "Obfuscated" "Double-VPN" "Onion+VPN" "P2P" "Favorites" "Exit")
    select grp in "${submgroups[@]}"
    do
        parent_menu
        case $grp in
            "All_Groups")
                group_all_menu
                ;;
            "Obfuscated")
                group_connect "Obfuscated_Servers"
                ;;
            "Double-VPN")
                group_connect "Double_VPN"
                ;;
            "Onion+VPN")
                group_connect "Onion_Over_VPN"
                ;;
            "P2P")
                group_connect "P2P"
                ;;
            "Favorites")
                favorites_menu "Group"
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submgroups[@]}" "$parent"
                ;;
        esac
    done
}
function settings_menu {
    heading "Settings"
    parent="Main"
    echo
    echo -e "$techpro$fw$rt$an$ks$tp$ob$no$ac$ip6$mn$dns$ld$al$fst$sshi"
    echo
    PS3=$'\n''Choose a Setting: '
    submsett=("Technology" "Protocol" "Firewall" "Routing" "Analytics" "KillSwitch" "TPLite" "Obfuscate" "Notify" "AutoConnect" "IPv6" "Meshnet" "Custom-DNS" "LAN Discovery" "Allowlist" "Account" "Restart" "Reset" "IPTables" "Logs" "Script" "Defaults" "Exit")
    select sett in "${submsett[@]}"
    do
        parent_menu
        case $sett in
            "Technology")
                technology_setting
                ;;
            "Protocol")
                protocol_setting
                ;;
            "Firewall")
                firewall_setting
                ;;
            "Routing")
                routing_setting
                ;;
            "Analytics")
                analytics_setting
                ;;
            "KillSwitch")
                killswitch_setting
                ;;
            "TPLite")
                tplite_setting
                ;;
            "Obfuscate")
                obfuscate_setting
                ;;
            "Notify")
                notify_setting
                ;;
            "AutoConnect")
                autoconnect_setting
                ;;
            "IPv6")
                ipv6_setting
                ;;
            "Meshnet")
                meshnet_menu "Settings"
                ;;
            "Custom-DNS")
                customdns_menu
                ;;
            "LAN Discovery")
                landiscovery_setting
                ;;
            "Allowlist")
                allowlist_setting
                ;;
            "Account")
                account_menu
                ;;
            "Restart")
                restart_service
                ;;
            "Reset")
                reset_app
                ;;
            "IPTables")
                iptables_menu
                ;;
            "Logs")
                service_logs
                ;;
            "Script")
                script_info
                ;;
            "Defaults")
                set_defaults_ask
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submsett[@]}" "$parent"
                ;;
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
    echo -e "Complete this command or hit 'Enter' for ${EColor}$pcity${Color_Off}"
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
    echo -e "${FColor}Please do not close this window.${Color_Off}"
    echo
    echo -e "Will connect to ${EColor}$pwhere${Color_Off} after $pminutes minutes."
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
    if [[ "$connected" == "connected" ]] && ! (( "$meshrouting" )); then
        if [[ "$rate_prompt" =~ ^[Yy]$ ]]; then
            rate_server
            echo
        fi
        if [[ "$pause_prompt" =~ ^[Yy]$ ]]; then
            echo
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
function main_menu {
    if [[ "$1" == "start" ]]; then
        echo -e "${EIColor}Welcome to nordlist!${Color_Off}"
        echo
    elif [[ "$fast1" =~ ^[Yy]$ ]] || [[ "$REPLY" == "$upmenu" ]]; then
        echo
        echo
    else
        echo
        echo
        read -n 1 -s -r -p "Press any key for the menu... "; echo
        echo
    fi
    #
    clear -x
    main_logo
    COLUMNS="$menuwidth"
    parent="Main"
    #
    # =====================================================================
    # ====== MAIN MENU ====================================================
    # =====================================================================
    #
    # To modify the list, for example changing Vancouver to Melbourne:
    # change "Vancouver" in both the first(horizontal) and second(vertical)
    # list to "Melbourne", and where it says
    # "nordvpn connect Vancouver" change it to
    # "nordvpn connect Melbourne". That's it.
    #
    # An almost unlimited number of menu items can be added.
    # Submenu functions can be added to the main menu for easier access.
    #
    PS3=$'\n''Choose an option: '
    #
    mainmenu=( "Vancouver" "Seattle" "Chicago" "Denver" "Atlanta" "US_Cities" "CA_Cities" "P2P-USA" "P2P-Canada" "Discord" "QuickConnect" "Random" "Favorites" "Countries" "Groups" "Settings" "Tools" "Meshnet" "Disconnect" "Exit" )
    #
    select opt in "${mainmenu[@]}"
    do
        parent_menu
        case $opt in
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
                main_header
                nordvpn connect us8247
                status
                openlink "https://discord.gg/83jsvGqpGk"
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
function check_depends {
    # https://stackoverflow.com/questions/16553089/dynamic-variable-names-in-bash
    # creates variables with value 0 or 1, eg $nordvpn_exists = 1
    #
    # check silently
    for program in nordvpn systemd-resolve #iptables systemctl firefox
    do
        name=$( echo "$program" | tr -d '-' )       # remove hyphens
        if command -v "$program" &> /dev/null; then
            printf -v "${name}_exists" '%s' '1'
        else
            printf -v "${name}_exists" '%s' '0'
        fi
    done
    #
    # echo results
    echo -e "${LColor}App Check${Color_Off}"
    for program in wg jq curl figlet lolcat iperf3 highlight speedtest-cli
    do
        name=$( echo "$program" | tr -d '-' )       # remove hyphens
        if command -v "$program" &> /dev/null; then
            echo -ne "${EIColor}Y${Color_Off}"
            printf -v "${name}_exists" '%s' '1'
        else
            echo -ne "${DIColor}N${Color_Off}"
            printf -v "${name}_exists" '%s' '0'
        fi
        echo "  $program"
    done
}
function start {
    # commands to run when the script first starts
    set_colors
    echo
    if [[ -n $SSH_TTY ]]; then
        # Check if the script is being run in an ssh session
        echo -e "${FColor}(The script is running over SSH)${Color_Off}"
        echo
        usingssh="1"
    fi
    if (( BASH_VERSINFO < 4 )); then
        echo "Bash Version $BASH_VERSION"
        echo -e "${WColor}Bash v4.0 or higher is required.${Color_Off}"
        echo
        exit 1
    fi
    check_depends
    echo
    if (( "$nordvpn_exists" )); then
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
    # Check if you are logged in.  This will cause a delay every time the script starts.
    #login_check
    #
    if nordvpn status | grep -i "update"; then
        # "A new version of NordVPN is available! Please update the application."
        clear -x
        echo
        echo -e "${WColor}** A NordVPN update is available **${Color_Off}"
        echo
        echo -e "${LColor}Before updating:${Color_Off}"
        echo "nordvpn set killswitch disabled"
        echo "nordvpn set autoconnect disabled"
        echo "nordvpn disconnect"
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
#
# Add repository and install:
#   cd ~/Downloads
#   wget -nc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
#   sudo apt install ~/Downloads/nordvpn-release_1.0.0_all.deb
#       or: sudo dpkg -i ~/Downloads/nordvpn-release_1.0.0_all.deb
#   sudo apt update
#   sudo apt install nordvpn
#
# Alternate install method:
#   When using "purge", the NordVPN repository should remain after using this method once.
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
#   Examples:
#       sudo apt install nordvpn=3.12.5
#       sudo apt install nordvpn=3.13.0
#       sudo apt install nordvpn=3.14.0
#
# GPG error: https//repo.nordvpn.com: The following signatures couldn't be verified
# because the public key is not available: NO_PUBKEY
#   sudo wget https://repo.nordvpn.com/gpg/nordvpn_public.asc -O - | sudo apt-key add -
#
# 'Whoops! /run/nordvpn/nordvpnd.sock not found.'
#   sudo systemctl start nordvpnd.service
#
# 'Permission denied accessing /run/nordvpn/nordvpnd.sock'
#   sudo usermod -aG nordvpn $USER
#   reboot
#
# 'Your account has expired. Renew your subscription now to continue
# enjoying the ultimate privacy and security with NordVPN.'
#   delete: /var/lib/nordvpn/data/settings.dat
#   delete: /home/username/.config/nordvpn/nordvpn.conf
#   nordvpn login
#
# Nord Account login without a GUI
#   nordvpn login --token <token>
#   To create a token, login to your Nord Account and navigate to:
#   Services - NordVPN - Access Token - Generate New Token
#
#   'man nordvpn' Note 2
#   SSH = in the SSH session connected to the device
#   Computer = on the computer you're using to SSH into the device
#       SSH
#           1. Run 'nordvpn login' and copy the URL
#       Computer
#           2. Open the copied URL in your web browser
#           3. Complete the login procedure
#           4. Right click on the 'Continue' button and select 'Copy link'
#       SSH
#           5. Run 'nordvpn login --callback <copied link>'
#           6. Run 'nordvpn account' to verify that the login was successful
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
#   Blocked by default:  https://nordvpn.com/blog/nordvpn-implements-ipv6-leak-protection
#   May 2022 - IPv6 capable servers:  us9591 us9592 uk1875 uk1876
#
# Manage NordVPN OpenVPN connections
#   https://github.com/jotyGill/openpyn-nordvpn
#
# OpenVPN Control Script
#   https://gist.github.com/aivanise/58226db6491f3339cbfa645a9dc310c0
#
# Reconnect Scripts
#   https://github.com/mmnaseri/nordvpn-reconnect
#   https://forum.manjaro.org/t/nordvpn-bin-breaks-every-4-hours/80927/16
#   https://redd.it/povx2x
#
# NordVPN Linux GUI
#   https://github.com/imatefx/nordvpn-gui
#   https://github.com/GoBig87/NordVpnLinuxGUI
#   https://github.com/morpheusthewhite/nordpy
#   https://github.com/JimR21/nordvpn-linux-gui
#   https://github.com/byoso/Nord-Manager
#   https://github.com/insan271/gui-nordvpn-linux
#   https://github.com/vfosterm/NordVPN-NetworkManager-Gui
#
# Output recommended servers with option to ping each server
#   https://github.com/trishmapow/nordvpn-tools
#
# NordVPN status and settings tray app.
#   https://github.com/dvilelaf/NordIndicator
#
# Cinnamon Applets (Cinnamon Desktop Environment)
#   NordVPN Indicator
#       https://cinnamon-spices.linuxmint.com/applets/view/331
#   VPN Look-Out Applet
#       https://cinnamon-spices.linuxmint.com/applets/view/305
#
#   Bash Sensors
#       Shows the NordVPN connection status in the panel and runs nordlist.sh when clicked.
#       Mint-Menu - "Applets" - Download tab - "Bash-Sensors" - Install - Manage tab - (+)Add to panel
#       https://cinnamon-spices.linuxmint.com/applets/view/231
#
#       To use the NordVPN icons from https://github.com/ph202107/nordlist/tree/main/icons
#       Download the icons to your device and modify "PATH_TO_ICON" in the command below.
#       Green = Connected, Red = Disconnected.  Screenshot:  https://github.com/ph202107/nordlist/blob/main/screenshots
#           Title:  NordVPN
#           Refresh Interval:  15 seconds or choose
#           Shell:  bash
#           Command 1: blank
#           Two Line Mode:  Off
#           Dynamic Icon:  On
#           Static Icon or Command:
#               if [[ "$(nordvpn status | grep -i "Status" | cut -f2 -d':' | cut -c 2- | tr '[:upper:]' '[:lower:]')" == "connected" ]]; then echo "PATH_TO_ICON/nord.round.green.png"; else echo "PATH_TO_ICON/nord.round.red.png"; fi
#           Dynamic Tooltip:  On
#           Tooltip Command:
#               To show the connection status and city:
#                   echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -i -E "Status|City"
#               To show the entire output of "nordvpn status":
#                   echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -v -i -E "update|feature"
#           Command on Applet Click:
#               gnome-terminal -- bash -c "echo -e '\033]2;'NORD'\007'; PATH_TO_SCRIPT/nordlist.sh; exec bash"
#           Display Output:  Off
#           Command on Startup:  blank
#
#       To use unicode symbols
#       Green Checkmark = Connected, Red X = Disconnected
#       Alternate Symbols: https://unicode-table.com/en/sets/check/
#           Title:  NordVPN
#           Refresh Interval:  15 seconds or choose
#           Shell:  bash
#           Command 1:
#               if [[ "$(nordvpn status | grep -i "Status" | cut -f2 -d':' | cut -c 2- | tr '[:upper:]' '[:lower:]')" == "connected" ]]; then echo -e "\u2705"; else echo -e "\u274c"; fi
#           Two Line Mode:  Off
#           Dynamic Icon:  Off
#           Static Icon or Command: blank
#           Dynamic Tooltip:  On
#           Tooltip Command:
#               To show the connection status and city:
#                   echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -i -E "Status|City"
#               To show the entire output of "nordvpn status":
#                   echo "NordVPN"; nordvpn status | tr -d '\r' | tr -d '-' | grep -v -i -E "update|feature"
#           Command on Applet Click:
#               gnome-terminal -- bash -c "echo -e '\033]2;'NORD'\007'; PATH_TO_SCRIPT/nordlist.sh; exec bash"
#           Display Output:  Off
#           Command on Startup:  blank
#
#       Command to reload the Bash Sensors applet:
#           dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'bash-sensors@pkkk' string:'APPLET'
#
# Other Troubleshooting
#   systemctl status nordvpnd.service
#   systemctl status nordvpn.service
#   journalctl -u nordvpnd.service
#   journalctl -u nordvpnd > ~/Downloads/nordlog.txt
#   journalctl -xe
#   sudo service network-manager restart
#   sudo service nordvpnd restart
#   sudo systemctl restart nordvpnd.service
#   sudo systemctl restart nordvpn.service
#   sudo systemctl restart networking
#
# Change Window Title (gnome terminal)
#   Add function to bashrc. Usage: $ set-title NORD
#   nano ~/.bashrc
#       function set-title {
#         if [[ -z "$ORIG" ]]; then
#           ORIG=$PS1
#         fi
#         TITLE="\[\e]2;$*\a\]"
#         PS1=${ORIG}${TITLE}
#       }
#
# Startup Script (10s delay)
#   Show nordvpn status, move terminal to workspace 2 and rename.
#       gnome-terminal -- bash -c "nordvpn status; exec bash"
#       wmctrl -r "myusername" -t 1 && wmctrl -r "myusername" -T "NORD"
#
