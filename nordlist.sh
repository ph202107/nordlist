#!/bin/bash
# shellcheck disable=SC2034,SC2129,SC2154
# unused color variables, individual redirects, var assigned
#
# Tested with NordVPN Version 3.15.0 on Linux Mint 20.3
# November 5, 2022
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added a
# lot of comments to help fellow newbies customize the script.
#
# Screenshots:
# https://i.imgur.com/k9pb5U4.png
# https://i.imgur.com/uPSgJUR.png
# https://i.imgur.com/S3djlU5.png
# https://i.imgur.com/c31ZwqJ.png
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
#       eg. /home/username/bin/nordlist.sh
# 2) Make the script executable with
#       "chmod +x nordlist.sh"
# 3) To generate ASCII images and to use NordVPN API functions
#       these small programs are required *
#       eg. "sudo apt install figlet lolcat curl jq"
# 4) At the terminal type "nordlist.sh"
#
# (*) The script will work without figlet and lolcat by specifying
#     "ascii_standard" in "function main_logo"
#
# =====================================================================
# Other Programs Used
# ====================
#
# wireguard-tools  Settings-Tools-WireGuard    (function wireguard_gen)
# speedtest-cli    Settings-Tools-Speed Tests  (function speedtest_menu)
# highlight        Settings-Script             (function script_info)
#
# eg.   "sudo apt install wireguard wireguard-tools"
#       "sudo apt install speedtest-cli highlight"
#
# For VPN On/Off status on the desktop I use the Linux Mint Cinnamon
# applet "Bash Sensors". Screenshot: https://i.imgur.com/fLOoyiJ.jpg
# The config is in the "Notes" at the bottom of the script.
#
# =====================================================================
# Sudo Usage
# ===========
#
#   These functions will ask for a sudo password:
#   - function restart_service
#   - function iptables_status
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
#default_dns="192.168.1.70"; dnsdesc="PiHole"
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
# Save generated WireGuard config files into this folder.
# Use the absolute path, no trailing slash (/)
wgdir="/home/$USER/Downloads"
#
# Specify the absolute path and filename to store a local list of all
# the NordVPN servers.  Avoids API server timeouts.  Create the list at:
# Settings - Tools - NordVPN API - All VPN Servers - Update List
allvpnfile="/home/$USER/Downloads/allnordservers.txt"
#
# When changing servers disconnect the VPN first, then connect to the
# new server.  "y" or "n"
disconnect="n"
#
# Always 'Rate Server' when disconnecting via the main menu. "y" or "n"
alwaysrate="y"
#
# Show the logo when the script exits.  "y" or "n"
exitlogo="y"
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
# Set 'menuwidth' to your terminal width or lower eg. menuwidth="70"
# Lowering the value will compact the menus horizontally.
# Leave blank to have the menu width change with the window size.
menuwidth="70"
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
# Automatically change these settings without prompting:
# Firewall, Analytics, KillSwitch, TPLite, Notify, AutoConnect, IPv6
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
# Always enable the Kill Switch (and Firewall) when connecting
# to these groups:  Obfuscated, Double-VPN, Onion+VPN, P2P
# (Unless connecting through "All_Groups")
fast5="n"
#
# Always choose the same protocol when asked to choose TCP or UDP.
# (Unless changing the setting through Settings-Protocol.)
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
# Whitelist & Default Settings
# =============================
#
# Add your whitelist commands to "function whitelist_commands"
# Set up a default NordVPN config in "function set_defaults"
#
# =====================================================================
# Main Menu
# ==========
#
# The Main Menu starts on line 3141 (function main_menu).
# Configure the first nine main menu items to suit your needs.
#
# Enjoy!
#
# ==End================================================================
#
function whitelist_commands {
    # Add your whitelist configuration commands here.
    # Enter one command per line.
    # whitelist_start (keep this line)
    #
    #nordvpn whitelist remove all
    #nordvpn whitelist add subnet 192.168.1.0/24
    #
    # whitelist_end (keep this line)
    echo
}
function set_defaults {
    # Calling this function can be useful to change multiple settings
    # at once and get back to a typical configuration.
    #
    # Configure as needed and comment-out the line below.
    echo -e "${WColor}** 'function set_defaults' not configured **${Color_Off}"; echo; return
    #
    # Notes:
    # - The VPN will be disconnected
    # - NordLynx is UDP only
    # - Obfuscate requires OpenVPN
    # - Kill Switch requires Firewall
    # - TPLite disables CustomDNS and vice versa
    #
    # For each setting uncomment one of the two choices (or neither).
    #
    disconnect_vpn "force"
    #
    if [[ "$technology" == "openvpn" ]]; then nordvpn set technology nordlynx; set_vars; fi
    #if [[ "$technology" == "nordlynx" ]]; then nordvpn set technology openvpn; set_vars; fi
    #
    if [[ "$protocol" == "TCP" ]]; then nordvpn set protocol UDP; fi
    #if [[ "$protocol" == "UDP" ]]; then nordvpn set protocol TCP; fi
    #
    if [[ "$firewall" == "disabled" ]]; then nordvpn set firewall enabled; fi
    #if [[ "$firewall" == "enabled" ]]; then nordvpn set firewall disabled; fi
    #
    #if [[ "$routing" == "disabled" ]]; then nordvpn set routing enabled; fi
    #if [[ "$routing" == "enabled" ]]; then nordvpn set routing disabled; fi
    #
    #if [[ "$analytics" == "disabled" ]]; then nordvpn set analytics enabled; fi
    #if [[ "$analytics" == "enabled" ]]; then nordvpn set analytics disabled; fi
    #
    #if [[ "$killswitch" == "disabled" ]]; then nordvpn set killswitch enabled; fi
    if [[ "$killswitch" == "enabled" ]]; then nordvpn set killswitch disabled; fi
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
    echo -e "${LColor}Default configuration applied.${Color_Off}"
    echo
}
function ascii_standard {
    # This ASCII can display above the main menu if you prefer to use
    # other ASCII art. Place any ASCII art between cat << "EOF" and EOF
    # and specify ascii_standard in "function main_logo".
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
        #figlet NordVPN                         # standard font in mono
        #figlet NordVPN | lolcat -p 0.8         # standard font colorized
        #figlet -f slant NordVPN | lolcat       # slant font, colorized
        #figlet "$city" | lolcat -p 1           # display the city name, more rainbow
        figlet -f slant "$city" | lolcat       # city in slant font
        #figlet "$country" | lolcat -p 1.5      # display the country
        #figlet "$transferd" | lolcat  -p 1     # display the download statistic
        #
    else
        figlet NordVPN                          # style when disconnected
    fi
}
function main_logo {
    # the ascii and stats shown above the main_menu and on script exit
    set_vars
    if [[ "$1" != "stats_only" ]]; then
        #
        # Specify  ascii_standard or ascii_custom on the line below.
        ascii_custom
        #
    fi
    echo -e "$connectedcl ${CIColor}$city ${COColor}$country ${SVColor}$server ${IPColor}$ipaddr${Color_Off}"
    echo -e "$techpro$fw$rt$an$ks$tp$ob$no$ac$ip6$mn$dns$wl$fst"
    echo -e "$transferc ${UPColor}$uptime${Color_Off}"
    if [[ -n $transferc ]]; then echo; fi
    # all indicators: $techpro$fw$rt$an$ks$tp$ob$no$ac$ip6$mn$dns$wl$fst
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
            echo -e "${H2Color}== $1 ==${Color_Off}"
        else
            echo -e "${H1Color}== $1 ==${Color_Off}"
        fi
        echo
        COLUMNS=$menuwidth
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
        echo -e "${H1Color}== $1 ==${Color_Off}"
        echo
    fi
    COLUMNS=$menuwidth
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
    SColor=${BBlue}         # Color for the ascii_standard image
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
    # search "status" array by line (case insensitive)
    printf '%s\n' "${nstatus[@]}" | grep -i "$1"
}
function nsettings_search {
    # search "settings" array by line (case insensitive)
    printf '%s\n' "${nsettings[@]}" | grep -i "$1"
}
function set_vars {
    # Store info in arrays (BASH v4)
    readarray -t nstatus < <( nordvpn status | tr -d '\r' )
    readarray -t nsettings < <( nordvpn settings | tr -d '\r' | tr '[:upper:]' '[:lower:]' )
    #
    # "nordvpn status" - array nstatus - search function nstatus_search
    # When disconnected, $connected is the only variable from nstatus
    connected=$(nstatus_search "Status" | cut -f2 -d':' | cut -c 2- | tr '[:upper:]' '[:lower:]')
    nordhost=$(nstatus_search "Current server" | cut -f3 -d' ')     # full hostname
    server=$(echo "$nordhost" | cut -f1 -d'.')                      # shortened hostname
    # country and city names may have spaces
    country=$(nstatus_search "Country" | cut -f2 -d':' | cut -c 2-)
    city=$(nstatus_search "City" | cut -f2 -d':' | cut -c 2-)
    ip=$(nstatus_search "Server IP" | cut -f 2-3 -d' ')             # includes "IP: "
    ipaddr=$(echo "$ip" | cut -f2 -d' ')                            # IP address only
    #technology2=$(nstatus_search "technology" | cut -f3 -d' ')     # variable not used
    protocol2=$(nstatus_search "protocol" | cut -f3 -d' ' | tr '[:lower:]' '[:upper:]')
    transferd=$(nstatus_search "Transfer" | cut -f 2-3 -d' ')       # download stat with units
    transferu=$(nstatus_search "Transfer" | cut -f 5-6 -d' ')       # upload stat with units
    #transfer="\u25bc $transferd  \u25b2 $transferu"                # unicode up/down arrows
    uptime=$(nstatus_search "Uptime" | cut -f 1-5 -d' ')
    #
    # "nordvpn settings" - array nsettings (all elements lowercase) - search function nsettings_search
    # $protocol and $obfuscate are not listed when using NordLynx
    technology=$(nsettings_search "Technology" | cut -f2 -d':' | cut -c 2-)
    protocol=$(nsettings_search "Protocol" | cut -f2 -d' ' | tr '[:lower:]' '[:upper:]')
    firewall=$(nsettings_search "Firewall:" | cut -f2 -d' ')
    fwmark=$(nsettings_search "Firewall Mark" | cut -f3 -d' ')
    routing=$(nsettings_search "Routing" | cut -f2 -d' ')
    analytics=$(nsettings_search "Analytics" | cut -f2 -d' ')
    killswitch=$(nsettings_search "Kill" | cut -f3 -d' ')
    #tplite=$(printf '%s\n' "${nsettings[@]}" | grep -i -E "CyberSec|Threat" | awk '{print $NF}')
    #tplite=$(nsettings_search "CyberSec" | cut -f2 -d' ')           # CyberSec (v3.13-)
    tplite=$(nsettings_search "Threat" | cut -f4 -d' ')              # Threat Protection Lite (v3.14+)
    obfuscate=$(nsettings_search "Obfuscate" | cut -f2 -d' ')
    notify=$(nsettings_search "Notify" | cut -f2 -d' ')
    autoconnect=$(nsettings_search "Auto" | cut -f2 -d' ')
    ipversion6=$(nsettings_search "IPv6" | cut -f2 -d' ')
    meshnet=$(nsettings_search "Meshnet" | cut -f2 -d' ' | tr -d '\n')
    customdns=$(nsettings_search "DNS" | cut -f2 -d' ')                  # disabled or not=disabled
    dns_servers=$(nsettings_search "DNS" | tr '[:lower:]' '[:upper:]')   # Server IPs, includes "DNS: "
    whitelist=$( printf '%s\n' "${nsettings[@]}" | grep -A100 -i "whitelist" )
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
        transferc="${DLColor}\u25bc $transferd ${ULColor}\u25b2 $transferu ${Color_Off}"
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
    else
        rt="${DIColor}[RT]${Color_Off}"
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
    if [[ -n "${whitelist[*]}" ]]; then # not empty
        wl="${EIColor}[WL]${Color_Off}"
    else
        wl="${DIColor}[WL]${Color_Off}"
    fi
    #
    if [[ ${allfast[*]} =~ [Yy] ]]; then
        fst="${FIColor}[F]${Color_Off}"
    else
        fst=""
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
    readarray -t ipinfo < <( timeout 10 curl --silent ipinfo.io )
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
                echo -ne "${LColor}($nordhost) ${Color_Off}"
                ping -c 3 -q "$ipaddr" | grep -A4 -i "statistics"
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
            if [[ "$technology" == "openvpn" ]]; then
                echo -ne "${LColor}(External IP) ${Color_Off}"
                ping -c 3 -q "$extip" | grep -A4 -i "statistics"
                echo
            elif [[ "$server" == *"-"* ]] && [[ "$server" != *"onion"* ]]; then
                # ping both hops of Double-VPN servers when using NordLynx
                echo -ne "${LColor}(Double-VPN) ${Color_Off}"
                ping -c 3 -q "$extip" | grep -A4 -i "statistics"
                echo
            fi
        fi
    fi
    date
    echo
    if [[ "$exitapplet" =~ ^[Yy]$ ]]; then
        # reload the "Bash Sensors" Linux Mint Cinnamon applet
        dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'bash-sensors@pkkk' string:'APPLET'
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
    if [[ "$2" == "ask" ]]; then
        read -n 1 -r -p "$(echo -e "Open ${EColor}$1${Color_Off} ? (y/n) ")"; echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    if [[ "$1" == *"http"* ]] && [[ "$newfirefox" =~ ^[Yy]$ ]]; then
        nohup /usr/bin/firefox --new-window "$1" > /dev/null 2>&1 &
    else
        nohup xdg-open "$1" > /dev/null 2>&1 &
    fi
    if [[ "$3" == "exit" ]]; then
        echo
        exit
    fi
}
function invalid_option {
    echo
    echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
    echo
    echo "Select any number from 1-$1 ($1 to Exit)."
}
function create_list {
    #
    # remove notices by keyword
    listexclude="update|feature"
    #
    case "$1" in
        "country")
            readarray -t countrylist < <( nordvpn countries | tr -d '\r' | tr -d '-' | grep -v -i -E "$listexclude" | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort )
            rcountry=$( printf '%s\n' "${countrylist[ RANDOM % ${#countrylist[@]} ]}" )
            # Replaced "Bosnia_And_Herzegovina" with "Sarajevo" to help compact the list.
            countrylist=("${countrylist[@]/Bosnia_And_Herzegovina/Sarajevo}")
            countrylist+=( "Random" )
            countrylist+=( "Exit" )
            ;;
        "city")
            readarray -t citylist < <( nordvpn cities "$xcountry" | tr -d '\r' | tr -d '-' | grep -v -i -E "$listexclude" | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort )
            rcity=$( printf '%s\n' "${citylist[ RANDOM % ${#citylist[@]} ]}" )
            if (( "${#citylist[@]}" > 1 )); then
                citylist+=( "Random" )
                citylist+=( "Best" )
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
    create_list "country"
    numcountries=${#countrylist[@]}
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Countries with Obfuscation support"
        echo
    fi
    PS3=$'\n''Choose a Country: '
    select xcountry in "${countrylist[@]}"
    do
        if [[ "$xcountry" == "Exit" ]]; then
            main_menu
        elif [[ "$xcountry" == "Random" ]]; then
            xcountry="$rcountry"
            city_menu
        elif (( 1 <= REPLY )) && (( REPLY <= numcountries )); then
            city_menu
        else
            invalid_option "$numcountries"
        fi
    done
}
function city_menu {
    # all available cities in $xcountry
    heading "$xcountry"
    echo
    if [[ "$xcountry" == "Sarajevo" ]]; then  # special case
        xcountry="Bosnia_and_Herzegovina"
        echo -e "${H1Color}== $xcountry ==${Color_Off}"
        echo
    fi
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
        if [[ "$xcity" == "Exit" ]]; then
            main_menu
        elif [[ "$xcity" == "Best" ]]; then
            heading "$xcountry"
            disconnect_vpn
            echo "Connect to the best available city."
            echo
            nordvpn connect "$xcountry"
            status
            exit
        elif [[ "$xcity" == "Random" ]]; then
            heading "Random"
            disconnect_vpn
            echo "Connect to $rcity $xcountry"
            echo
            nordvpn connect "$rcity"
            status
            exit
        elif (( 1 <= REPLY )) && (( REPLY <= numcities )); then
            heading "$xcity"
            disconnect_vpn
            echo "Connect to $xcity $xcountry"
            echo
            nordvpn connect "$xcity"
            status
            exit
        else
            invalid_option "$numcities"
        fi
    done
}
function host_connect {
    heading "Hostname"
    echo "Connect to specific servers by name."
    echo
    echo "This option may be useful to test multiple servers for"
    echo "latency, load, throughput, app compatibility, etc."
    echo "Will not exit after connecting to a server."
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
    # echo "Netflix Region and Status"
    # curl --silent "http://api-global.netflix.com/apps/applefuji/config" | grep -E 'geolocation.country|geolocation.status'
    # echo
}
function random_worldwide {
    # connect to a random city worldwide
    #
    create_list "country"
    xcountry="$rcountry"
    create_list "city"
    #
    heading "Random"
    disconnect_vpn
    echo "Connect to $rcity $rcountry"
    echo
    nordvpn connect "$rcity"
    status
    exit
}
function group_killswitch {
    if [[ "$killswitch" == "disabled" ]]; then
        if [[ "$fast5" =~ ^[Yy]$ ]]; then
            echo -e "${FColor}[F]ast5 is enabled.  Enabling the Kill Switch.${Color_Off}"
            echo
            if [[ "$firewall" == "disabled" ]]; then
                nordvpn set firewall enabled; wait
                echo
            fi
            nordvpn set killswitch enabled; wait
            echo
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
            read -r -p "Enter the $1 location: " location
            REPLY="y"
        fi
    fi
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
            technology_setting "back" "no_heading"
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
                echo
            fi
        fi
        group_killswitch
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
    # $1 = "back" - ignore fast3, return
    # $2 = "no_heading" - skip the heading
    #
    if [[ "$2" != "no_heading" ]]; then
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
        echo
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
    else
        read -n 1 -r -p "$chgprompt"; echo
    fi
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
    change_setting "routing" "back" # disable fast2
    main_menu
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
    echo "Send OS notifications when the VPN status changes."
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
    change_setting "ipv6"
}
function obfuscate_setting {
    # not available when using NordLynx
    # must disconnect/reconnect to change setting
    heading "Obfuscate"
    if [[ "$technology" == "nordlynx" ]]; then
        echo -e "Technology is currently set to $technologydc."
        echo
        echo "Obfuscation is not available when using $technologyd."
        echo "Change Technology to OpenVPN to use Obfuscation."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting and return? (y/n) "; echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            technology_setting "back"
            obfuscate_setting
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
function meshnet_menu {
    # https://support.nordvpn.com/General-info/Features/1847604142/Using-Meshnet-on-Linux.htm
    # https://nordvpn.com/features/meshnet
    # https://support.nordvpn.com/General-info/Features/1845333902/What-is-Meshnet.htm
    # https://nordvpn.com/blog/meshnet-feature-launch/
    heading "Meshnet"
    echo "Using NordLynx, Meshnet lets you access devices over encrypted private"
    echo "  tunnels directly, instead of connecting to a VPN server."
    echo "With Meshnet enabled up to 10 devices using the NordVPN app with the"
    echo "  same account are linked automatically."
    echo "Connect up to 50 external devices by sending invitations."
    echo "  Connections with an external device are isolated as a private pair."
    echo
    echo -e "$mn Meshnet is $meshnetc."
    echo
    PS3=$'\n''Choose an Option: '
    submesh=("Enable/Disable" "Peer List" "Peer Refresh" "Peer Remove" "Peer Incoming" "Peer Routing" "Peer Local" "Peer Connect" "Invite List" "Invite Send" "Invite Accept" "Invite Deny" "Invite Revoke" "Support" "Exit")
    select mesh in "${submesh[@]}"
    do
        case $mesh in
            "Enable/Disable")
                clear -x
                echo
                change_setting "meshnet" "back"
                meshnet_menu
                ;;
            "Peer List")
                heading "Peer List" "txt"
                echo "Lists available peers in a meshnet."
                echo
                echo -e "${H1Color}nordvpn meshnet peer list${Color_Off}"
                echo
                nordvpn meshnet peer list
                ;;
            "Peer Refresh")
                heading "Peer Refresh" "txt"
                echo "Refreshes the meshnet in case it was not updated automatically."
                echo
                echo -e "${H1Color}nordvpn meshnet peer refresh${Color_Off}"
                echo
                nordvpn meshnet peer refresh
                ;;
            "Peer Remove")
                heading "Peer Remove" "txt"
                echo "Removes a peer from the meshnet."
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
                echo "Usage: nordvpn meshnet peer incoming [options] [public_key|hostname|ip]"
                echo
                echo "Options:"
                echo "  allow - Allows a meshnet peer to send traffic to this device."
                echo "  deny  - Denies a meshnet peer to send traffic to this device."
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
                echo "Usage: nordvpn meshnet peer routing [options] [public_key|hostname|ip]"
                echo
                echo "Options:"
                echo "  allow - Allows a meshnet peer to route traffic through this device."
                echo "  deny  - Denies a meshnet peer to route traffic through this device."
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
                echo "Usage: nordvpn meshnet peer local [options] [public_key|hostname|ip]"
                echo
                echo "Options:"
                echo "  allow - Allows the peer access to the local network when routing"
                echo "  deny  - Denies the peer access to the local network when routing"
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
            "Peer Connect")
                heading "Peer Connect" "txt"
                echo "Treats a peer as a VPN server and connects to it if the"
                echo " peer has allowed traffic routing."
                echo
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
            "Invite List")
                heading "Invite List" "txt" "alt"
                echo "Displays the list of all sent and received meshnet invitations."
                echo
                echo -e "${H2Color}nordvpn meshnet invite list${Color_Off}"
                echo
                nordvpn meshnet invite list
                ;;
            "Invite Send")
                heading "Invite Send" "txt" "alt"
                echo "Sends an invitation to join the mesh network."
                echo
                echo "Usage: nordvpn meshnet invite send [options] [email]"
                echo
                echo "Options:"
                echo "  --allow-incoming-traffic"
                echo "      Allow incoming traffic from a peer. (default: false)"
                echo "  --allow-traffic-routing"
                echo "      Allow the peer to route traffic through this device. (default: false)"
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
                echo "Accepts an invitation to join the inviter's mesh network."
                echo
                echo "Usage: nordvpn meshnet invite accept [options] [email]"
                echo
                echo "Options:"
                echo "  --allow-incoming-traffic"
                echo "      Allow incoming traffic from the peer. (default: false)"
                echo "  --allow-traffic-routing"
                echo "      Allow the peer to route traffic through this device. (default: false)"
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
                echo "Denies an invitation to join the inviter's mesh network."
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
                echo "Revokes a sent invitation."
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
            "Support")
                heading "Support" "txt" "alt"
                openlink "https://support.nordvpn.com/General-info/Features/1847604142/Using-Meshnet-on-Linux.htm" "ask"
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submesh[@]}"
                ;;
        esac
    done
}
function customdns_menu {
    heading "CustomDNS"
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
    PS3=$'\n''Choose an Option: '
    # Note submcdns[@] - new entries should keep the same format for the "Test Servers" option
    # eg Name<space>DNS1<space>DNS2
    submcdns=("Nord 103.86.96.100 103.86.99.100" "AdGuard 94.140.14.14 94.140.15.15" "OpenDNS 208.67.220.220 208.67.222.222" "CB-Security 185.228.168.9 185.228.169.9" "Quad9 9.9.9.9 149.112.112.11" "Cloudflare 1.0.0.1 1.1.1.1" "Google 8.8.4.4 8.8.8.8" "Specify or Default" "Disable Custom DNS" "Flush DNS Cache" "Test Servers" "Exit")
    select cdns in "${submcdns[@]}"
    do
        case $cdns in
            "Nord 103.86.96.100 103.86.99.100")
                echo
                nordvpn set dns 103.86.96.100 103.86.99.100
                ;;
            "AdGuard 94.140.14.14 94.140.15.15")
                echo
                nordvpn set dns 94.140.14.14 94.140.15.15
                ;;
            "OpenDNS 208.67.220.220 208.67.222.222")
                echo
                nordvpn set dns 208.67.220.220 208.67.222.222
                ;;
            "CB-Security 185.228.168.9 185.228.169.9")
                # Clean Browsing Security 185.228.168.9 185.228.169.9
                # Clean Browsing Adult 185.228.168.10 185.228.169.11
                # Clean Browsing Family 185.228.168.168 185.228.169.168
                echo
                nordvpn set dns 185.228.168.9 185.228.169.9
                ;;
            "Quad9 9.9.9.9 149.112.112.11")
                echo
                nordvpn set dns 9.9.9.9 149.112.112.11
                ;;
            "Cloudflare 1.0.0.1 1.1.1.1")
                echo
                nordvpn set dns 1.0.0.1 1.1.1.1
                ;;
            "Google 8.8.4.4 8.8.8.8")
                echo
                nordvpn set dns 8.8.4.4 8.8.8.8
                ;;
            "Specify or Default")
                echo
                echo "Enter the DNS server IPs or hit 'Enter' for default."
                echo -e "Default: ${LColor}$dnsdesc ($default_dns)${Color_Off}"
                echo
                read -r -p "Up to 3 DNS server IPs: " dns3srvrs
                dns3srvrs=${dns3srvrs:-$default_dns}
                echo
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
                invalid_option "${#submcdns[@]}"
                ;;
        esac
    done
}
function whitelist_setting {
    # $1 = "back" - return
    #
    heading "Whitelist"
    echo "Restore a default whitelist after installation, using 'Reset' or"
    echo "making other changes. Edit the script to modify the function."
    echo
    echo -e "${EColor}Current Settings:${Color_Off}"
    if [[ -n "${whitelist[*]}" ]]; then
        echo -ne "$wl "
        printf '%s\n' "${whitelist[@]}"
    else
        echo -e "$wl No whitelist entries."
    fi
    echo
    echo -e "${LColor}function whitelist_commands${Color_Off}"
    startline=$(grep -m1 -n "whitelist_start" "$0" | cut -f1 -d':')
    endline=$(( $(grep -m1 -n "whitelist_end" "$0" | cut -f1 -d':') - 1 ))
    numlines=$(( endline - startline ))
    if (( "$highlight_exists" )); then
        highlight -l -O xterm256 "$0" | head -n "$endline" | tail -n "$numlines"
    else
        cat -n "$0" | head -n "$endline" | tail -n "$numlines"
    fi
    echo
    echo -e "Type ${WColor}C${Color_Off} to clear the current whitelist."
    echo -e "Type ${FIColor}E${Color_Off} to edit the script."
    echo
    read -n 1 -r -p "Apply your default whitelist settings? (y/n/C/E) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        whitelist_commands
        set_vars
    elif [[ $REPLY =~ ^[Cc]$ ]]; then
        nordvpn whitelist remove all
        set_vars
    elif [[ $REPLY =~ ^[Ee]$ ]]; then
        echo -e "Modify ${LColor}function whitelist_commands${Color_Off} starting on ${FColor}line $(( startline + 1 ))${Color_Off}"
        echo
        openlink "$0" "noask" "exit"
    else
        echo "No changes made."
    fi
    if [[ -n "${whitelist[*]}" ]]; then
        echo
        echo -ne "$wl "
        printf '%s\n' "${whitelist[@]}"
    fi
    if [[ "$1" == "back" ]]; then
        echo
        return
    fi
    main_menu
}
function login_nogui {
    heading "Login (no GUI)" "txt"
    echo "For now, users without a GUI can use "
    echo -e "${LColor}      nordvpn login --legacy${Color_Off}"
    echo -e "${LColor}      nordvpn login --username <username> --password <password>${Color_Off}"
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
function account_menu {
    heading "Account"
    echo
    PS3=$'\n''Choose an Option: '
    submacct=("Login (browser)" "Login (legacy)" "Login (token)" "Login (no GUI)" "Logout" "Account Info" "Register" "Nord Version" "Changelog" "Nord Manual" "Support" "NordAccount" "Exit")
    select acc in "${submacct[@]}"
    do
        case $acc in
            "Login (browser)")
                echo
                nordvpn login
                echo
                ;;
            "Login (legacy)")
                echo
                nordvpn login --legacy
                echo
                ;;
            "Login (token)")
                heading "Login (token)" "txt"
                echo "To create a token, login to your Nord Account and navigate to:"
                echo "Services - NordVPN - Access Token - Generate New Token"
                echo
                openlink "https://my.nordaccount.com/" "ask"
                echo
                read -r -p "Enter the login token: " logintoken
                if [[ -z $logintoken ]]; then
                    echo -e "${DColor}(Skipped)${Color_Off}"
                else
                    echo
                    nordvpn login --token "$logintoken"
                fi
                echo
                ;;
            "Login (no GUI)")
                login_nogui
                ;;
            "Logout")
                echo
                disconnect_vpn "force" "check_ks"
                nordvpn logout
                echo
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
                invalid_option "${#submacct[@]}"
                ;;
        esac
    done
}
function restart_service {
    # $1 = "after_reset" - login and prompt to apply default settings
    #
    heading "Restart"
    echo
    echo "Restart nordvpn services."
    echo -e "${WColor}"
    echo "Send commands:"
    echo "sudo systemctl restart nordvpnd.service"
    echo "sudo systemctl restart nordvpn.service"
    echo -e "${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl restart nordvpnd.service
        sudo systemctl restart nordvpn.service
        echo
        echo "Please wait 10s for the service to restart..."
        echo "If Auto-Connect is enabled NordVPN will reconnect."
        echo
        for t in {10..1}; do
            echo -n "$t "; sleep 1
        done
        echo
        sudo -K     # timeout sudo
        if [[ "$1" == "after_reset" ]]; then
            echo
            nordvpn login
            wait
            echo
            read -n 1 -r -p "Press any key after login is complete... "; echo
            echo
            set_defaults_ask
        fi
        status
        exit
    fi
    main_menu
}
function reset_app {
    heading "Reset Nord"
    echo
    echo "Reset the NordVPN app to default settings."
    echo "Requires NordVPN username/password to reconnect."
    echo -e "${WColor}"
    echo "Send commands:"
    echo "nordvpn set killswitch disabled"
    echo "nordvpn disconnect"
    echo "nordvpn logout"
    echo "nordvpn whitelist remove all"
    echo "nordvpn set defaults"
    echo "Restart nordvpn services"
    echo "nordvpn login"
    echo "Apply your default configuration"
    echo -e "${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # first four redundant
        if [[ "$killswitch" == "enabled" ]]; then
            nordvpn set killswitch disabled; wait
        fi
        disconnect_vpn "force"
        nordvpn logout; wait
        echo
        nordvpn whitelist remove all; wait
        echo
        nordvpn set defaults; wait
        echo
        echo -e "${EColor}Can also delete:${Color_Off}"
        echo "  /home/username/.config/nordvpn/nordvpn.conf"
        echo "  /var/lib/nordvpn/data/settings.dat"
        echo
        echo -e "${WColor}** Reminder **${Color_Off}"
        echo -e "${LColor}Reconfigure the Whitelist and other settings.${Color_Off}"
        echo
        read -n 1 -s -r -p "Press any key to restart the service..."; echo
        set_vars
        restart_service "after_reset"
    fi
    main_menu
}
function iptables_status {
    echo
    echo -e "The VPN is $connectedc. ${IPColor}$ip${Color_Off}"
    echo -e "$fw The Firewall is $firewallc. Firewall Mark: ${LColor}$fwmark${Color_Off}"
    echo -e "$rt Routing is $routing."
    echo -e "$ks The Kill Switch is $killswitchc."
    echo -e "$mn Meshnet is $meshnetc."
    if [[ -n "${whitelist[*]}" ]]; then
        echo -ne "$wl "
        printf '%s\n' "${whitelist[@]}"
    else
        echo -e "$wl No whitelist entries."
    fi
    echo
    echo -e "${LColor}sudo iptables -S${Color_Off}"
    sudo iptables -S
    echo
}
function iptables_menu {
    # https://old.reddit.com/r/nordvpn/comments/qgakq9/linux_killswitch_problems_iptables/
    # * changes in version 3.13.0 - "We made changes in firewall handling. Now we filter packets by firewall marks instead of IP addresses of VPN servers."
    heading "IPTables"
    echo "Flushing the IPTables may help resolve problems enabling or"
    echo "disabling the KillSwitch or with other connection issues."
    echo
    echo -e "${WColor}** WARNING **${Color_Off}"
    echo "  - This will CLEAR all of your Firewall rules"
    echo "  - Review 'function iptables_menu' before use"
    echo "  - Commands require 'sudo'"
    echo
    PS3=$'\n''Choose an option: '
    submipt=("View IPTables" "Firewall" "Routing" "KillSwitch" "Meshnet" "Whitelist" "Flush IPTables" "Restart Services" "Ping Google" "Disconnect" "Exit")
    select ipt in "${submipt[@]}"
    do
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
            "Whitelist")
                echo
                whitelist_setting "back"
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
            "Restart Services")
                echo
                echo -e "${WColor}Disconnect the VPN and restart nordvpn services.${Color_Off}"
                echo
                read -n 1 -r -p "Proceed? (y/n) "; echo
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [[ "$autoconnect" == "enabled" ]]; then
                        change_setting "autoconnect" "back"
                    fi
                    disconnect_vpn "force"
                    echo -e "${LColor}Restart NordVPN services. Wait 10s${Color_Off}"
                    echo
                    sudo systemctl restart nordvpnd.service
                    sudo systemctl restart nordvpn.service
                    for t in {10..1}; do
                        echo -n "$t "; sleep 1
                    done
                    echo
                    set_vars
                    iptables_status
                    echo -e "${LColor}ping -c 3 google.com${Color_Off}"
                    ping -c 3 google.com
                    echo
                else
                    echo
                    echo "No changes made."
                    echo
                fi
                ;;
            "Ping Google")
                iptables_status
                echo -e "${LColor}ping -c 3 google.com${Color_Off}"
                ping -c 3 google.com
                echo
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
                #sudo -K     # timeout sudo
                main_menu
                ;;
            *)
                invalid_option "${#submipt[@]}"
                ;;
        esac
    done
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
            echo -e "${WColor}** Please choose a number from 1 to 5"
            echo -e "('Enter' or 'x' to exit)${Color_Off}"
        fi
        echo
    done
}
function server_load {
    if [[ "$nordhost" == *"onion"* ]]; then
        echo -e "${LColor}$nordhost${Color_Off}"
        echo "Unable to check the server load for Onion+VPN servers."
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
    if (( ${#allnordservers[@]} == 0 )); then
        if [[ -e "$allvpnfile" ]]; then
            echo -e "${EColor}Server List: ${LColor}$allvpnfile${Color_Off}"
            head -n 1 "$allvpnfile"
            readarray -t allnordservers < <( tail -n +4 "$allvpnfile" )
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
    submallvpn=("List All Servers" "Double-VPN Servers" "Onion Servers" "SOCKS Servers" "Search" "Connect" "Update List" "Exit")
    select avpn in "${submallvpn[@]}"
    do
        case $avpn in
            "List All Servers")
                echo
                echo -e "${LColor}All the VPN Servers${Color_Off}"
                echo
                printf '%s\n' "${allnordservers[@]}"
                echo
                echo "All Servers: ${#allnordservers[@]}"
                echo
                ;;
            "Double-VPN Servers")
                echo
                echo -e "${LColor}Double-VPN Servers${Color_Off}"
                echo
                printf '%s\n' "${allnordservers[@]}" | grep "-" | grep -i -v -e "socks" -e "onion"
                echo
                # work in progress
                echo "Double-VPN Servers: $( printf '%s\n' "${allnordservers[@]}" | grep "-" | grep -i -v -e "socks" -e "onion" -c )"
                echo
                ;;
            "Onion Servers")
                echo
                echo -e "${LColor}Onion Servers${Color_Off}"
                echo
                printf '%s\n' "${allnordservers[@]}" | grep -i "onion"
                echo
                echo "Onion Servers: $( printf '%s\n' "${allnordservers[@]}" | grep -c -i "onion" )"
                echo
                ;;
            "SOCKS Servers")
                echo
                echo -e "${LColor}SOCKS Servers${Color_Off}"
                echo
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
                echo -e "${LColor}Search for '$allvpnsearch'${Color_Off}"
                echo
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
                if [[ -e "$allvpnfile" ]]; then
                    echo -e "${EColor}Server List: ${LColor}$allvpnfile${Color_Off}"
                    head -n 2 "$allvpnfile"
                    echo
                    read -n 1 -r -p "Update the list? (y/n) "; echo
                else
                    echo -e "${WColor}$allvpnfile does not exist.${Color_Off}"
                    echo
                    read -n 1 -r -p "Create the file? (y/n) "; echo
                fi
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [[ -e "$allvpnfile" ]]; then
                        echo "Retrieving the list of NordVPN servers..."
                        echo
                        readarray -t allnordservers < <( curl --silent https://api.nordvpn.com/server | jq --raw-output '.[].domain' | sort --version-sort )
                    fi
                    if (( ${#allnordservers[@]} < 1000 )); then
                        echo
                        echo -e "${WColor}Server list is empty. Parse Error? Try again later.${Color_Off}"
                        echo
                        if [[ -e "$allvpnfile" ]]; then
                            # rebuild array if it was blanked out on retrieval attempt
                            readarray -t allnordservers < <( tail -n +4 "$allvpnfile" )
                        fi
                    else
                        echo "Retrieved on: $( date )" > "$allvpnfile"
                        echo "Server Count: ${#allnordservers[@]}" >> "$allvpnfile"
                        echo >> "$allvpnfile"
                        printf '%s\n' "${allnordservers[@]}" >> "$allvpnfile"
                        echo -e "Saved as ${LColor}$allvpnfile${Color_Off}"
                        head -n 2 "$allvpnfile"
                        echo
                    fi
                fi
                ;;
            "Exit")
                nordapi_menu
                ;;
            *)
                invalid_option "${#submallvpn[@]}"
                ;;
        esac
    done
}
function nordapi_menu {
    # Commands copied from:
    # https://sleeplessbeastie.eu/2019/02/18/how-to-use-public-nordvpn-api/
    heading "Nord API"
    echo "Query the NordVPN Public API.  Requires 'curl' and 'jq'"
    echo "Commands may take a few seconds to complete."
    echo
    if [[ "$connected" == "connected" ]]; then
        echo -e "Connected to: ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    PS3=$'\n''API Call: '
    submapi=("Host Server Load" "Host Server Info" "Top 15 Recommended" "Top 15 By Country" "#Servers per Country" "All VPN Servers" "Change Host" "Connect" "Exit")
    select napi in "${submapi[@]}"
    do
        case $napi in
            "Host Server Load")
                echo
                echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
                echo
                server_load
                ;;
            "Host Server Info")
                echo
                echo -e "Retrieving ${LColor}$nordhost${Color_Off} information..."
                echo
                curl --silent https://api.nordvpn.com/server | jq '.[] | select(.domain == "'"$nordhost"'")'
                ;;
            "Top 15 Recommended")
                echo
                echo -e "${LColor}Top 15 Recommended VPN Servers${Color_Off}"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations" | jq --raw-output 'limit(15;.[]) | "  Server: \(.name)\nHostname: \(.hostname)\nLocation: \(.locations[0].country.name) - \(.locations[0].country.city.name)\n    Load: \(.load)\n"'
                ;;
            "Top 15 By Country")
                echo
                echo -e "${LColor}Top 15 VPN Servers by Country Code${Color_Off}"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | [.id, .name] | @tsv'
                echo
                read -r -p "Enter the Country Code: " ccode
                echo
                echo -e "${LColor}SERVER: ${EColor}%LOAD${Color_Off}"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=$ccode&\[servers_groups\]\[identifier\]=legacy_standard" | jq --raw-output --slurp ' .[] | sort_by(.load) | limit(15;.[]) | [.hostname, .load] | "\(.[0]): \(.[1])"'
                echo
                ;;
            "#Servers per Country")
                echo
                echo -e "${LColor}Number of VPN Servers in each Country${Color_Off}"
                echo
                curl --silent https://api.nordvpn.com/server | jq --raw-output '. as $parent | [.[].country] | sort | unique | .[] as $country | ($parent | map(select(.country == $country)) | length) as $count |  [$country, $count] |  "\(.[0]): \(.[1])"'
                echo
                ;;
            "All VPN Servers")
                allservers_menu
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
                invalid_option "${#submapi[@]}"
                ;;
        esac
    done
}
function change_host {
    echo
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
    echo "Generate a WireGuard config file from your currently active"
    echo "NordLynx connection.  Requires WireGuard/WireGuard-Tools."
    echo "Commands require sudo. Note: Keep your Private Key secure."
    echo
    set_vars
    wgcity=$( echo "$city" | tr -d ' ' )
    wgconfig="$wgcity"_"$server"_wg.conf    # Filename
    wgfull="$wgdir/$wgconfig"               # Full path and filename
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
    elif [[ -e "$wgfull" ]]; then
        echo -e "Current Server: ${EColor}$server.nordvpn.com${Color_Off}"
        echo
        echo -e "${WColor}$wgfull already exists${Color_Off}"
        echo
        openlink "$wgfull" "ask"
        return
    fi
    echo -e "Current Server: ${EColor}$server.nordvpn.com${Color_Off}"
    echo -e "${CIColor}$city ${COColor}$country ${IPColor}$ip ${Color_Off}"
    echo
    echo "Generate WireGuard config file:"
    echo -e "${LColor}$wgfull${Color_Off}"
    echo
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #
        address=$(/sbin/ifconfig nordlynx | grep 'inet ' | tr -s ' ' | cut -d" " -f3)
        #listenport=$(sudo wg showconf nordlynx | grep 'ListenPort = .*')
        privatekey=$(sudo wg showconf nordlynx | grep 'PrivateKey = .*')
        publickey=$(sudo wg showconf nordlynx | grep 'PublicKey = .*')
        endpoint=$(sudo wg showconf nordlynx | grep 'Endpoint = .*')
        #
        echo "# $server.nordvpn.com" > "$wgfull"
        echo "# $city $country" >> "$wgfull"
        echo "# Server $ip" >> "$wgfull"
        echo >> "$wgfull"
        echo "[INTERFACE]" >> "$wgfull"
        echo "Address = ${address}/32" >> "$wgfull"
        echo "${privatekey}" >> "$wgfull"
        echo "DNS = 103.86.96.100, 103.86.99.100" >> "$wgfull"
        echo >> "$wgfull"
        echo "[PEER]" >> "$wgfull"
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
function speedtest_menu {
    heading "SpeedTests"
    echo
    main_logo "stats_only"
    echo "Perform download and upload tests using the speedtest-cli,"
    echo "or open links to run browser-based speed tests."
    echo
    if ! (( "$speedtestcli_exists" )); then
        echo -e "${WColor}speedtest-cli could not be found.${Color_Off}"
        echo "Please install speedtest-cli"
        echo "eg. 'sudo apt install speedtest-cli'"
        echo
    fi
    PS3=$'\n''Select a test: '
    submspeed=( "Download & Upload" "Download Only" "Upload Only" "Latency & Load" "speedtest.net"  "speedof.me" "fast.com" "linode.com" "digitalocean.com" "nperf.com" "Exit" )
    select spd in "${submspeed[@]}"
    do
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
                if [[ "$connected" == "connected" ]]; then
                    echo -e "Connected to: ${EColor}$server.nordvpn.com${Color_Off}"
                else
                    echo -e "(VPN $connectedc)"
                    read -r -p "Enter a Hostname/IP [Default $default_vpnhost]: " nordhost
                    nordhost=${nordhost:-$default_vpnhost}
                    echo
                fi
                echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
                echo
                if [[ "$connected" == "connected" ]] && [[ "$technology" == "openvpn" ]]; then
                    if [[ "$obfuscate" == "enabled" ]]; then
                        echo -e "$ob - Unable to ping Obfuscated Servers"
                    else
                        echo -e "$technologydc - Server IP will not respond to ping."
                        echo "Attempt to ping your external IP instead."
                        echo
                        ipinfo_curl
                        if [[ -n "$extip" ]]; then
                            ping -c 3 "$extip"
                        fi
                    fi
                else
                    ping -c 3 "$nordhost"
                fi
                echo
                server_load
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
                invalid_option "${#submspeed[@]}"
                ;;
        esac
    done
}
function tools_menu {
    heading "Tools"
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
    submtools=( "NordVPN API" "External IP" "WireGuard" "Speed Tests" "Rate VPN Server" "Ping VPN" "Ping Google" "My TraceRoute" "ipleak cli" "ipleak.net" "dnsleaktest.com" "dnscheck.tools" "test-ipv6.com" "ipx.ac" "ipinfo.io" "locatejs.com" "browserleaks.com" "bash.ws" "Change Host" "World Map" "Outage Map" "Exit" )
    select tool in "${submtools[@]}"
    do
        case $tool in
            "NordVPN API")
                nordapi_menu
                ;;
            "External IP")
                echo
                ipinfo_curl
                ;;
            "WireGuard")
                wireguard_gen
                ;;
            "Speed Tests")
                speedtest_menu
                ;;
            "Rate VPN Server")
                echo
                rate_server
                ;;
            "Ping VPN")
                echo
                echo -e "${LColor}ping -c 5 $nordhost${Color_Off}"
                echo
                ping -c 5 "$nordhost"
                echo
                ;;
            "Ping Google")
                clear -x
                echo -e "${LColor}"
                echo "Ping Google DNS 8.8.8.8, 8.8.4.4"
                echo "Ping Cloudflare DNS 1.1.1.1, 1.0.0.1"
                echo "Ping Telstra Australia 139.130.4.4"
                echo -e "${FColor}"
                echo "(CTRL-C to quit)"
                echo -e "${Color_Off}"
                echo -e "${LColor}===== Google =====${Color_Off}"
                ping -c 5 8.8.8.8; echo
                ping -c 5 8.8.4.4; echo
                echo -e "${LColor}===== Cloudflare =====${Color_Off}"
                ping -c 5 1.1.1.1; echo
                ping -c 5 1.0.0.1; echo
                echo -e "${LColor}===== Telstra =====${Color_Off}"
                ping -c 5 139.130.4.4; echo
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
                echo -e "${Color_Off}$( curl --silent https://"$ipleak_session"-"$RANDOM".ipleak.net/dnsdetection/ | jq .ip )"
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
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submtools[@]}"
                ;;
        esac
    done
}
function set_defaults_ask {
    defaultsc="${LColor}[Defaults]${Color_Off}"'\n'
    echo
    echo -e "$defaultsc  Disconnect and apply the NordVPN settings"
    echo "  specified in 'function set_defaults'"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_defaults
        read -n 1 -r -p "$(echo -e "$defaultsc  Go to the 'Whitelist' setting? (y/n) ")"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            whitelist_setting "back"
        fi
        echo
        read -n 1 -r -p "$(echo -e "$defaultsc  Go to the 'CustomDNS' setting? (y/n) ")"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            set_vars
            customdns_menu
        fi
        main_menu
    fi
}
function script_info {
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
            invalid_option "$numgroups"
        fi
    done
}
function group_menu {
    heading "Groups"
    echo
    PS3=$'\n''Choose a Group: '
    submgroups=("All_Groups" "Obfuscated" "Double-VPN" "Onion+VPN" "P2P" "Exit")
    select grp in "${submgroups[@]}"
    do
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
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#submgroups[@]}"
                ;;
        esac
    done
}
function settings_menu {
    heading "Settings"
    echo
    echo -e "$techpro$fw$rt$an$ks$tp$ob$no$ac$ip6$mn$dns$wl$fst"
    echo
    PS3=$'\n''Choose a Setting: '
    submsett=("Technology" "Protocol" "Firewall" "Routing" "Analytics" "KillSwitch" "TPLite" "Obfuscate" "Notify" "AutoConnect" "IPv6" "Meshnet" "Custom-DNS" "Whitelist" "Account" "Restart" "Reset" "IPTables" "Tools" "Script" "Defaults" "Exit")
    select sett in "${submsett[@]}"
    do
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
                meshnet_menu
                ;;
            "Custom-DNS")
                customdns_menu
                ;;
            "Whitelist")
                whitelist_setting
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
            "Tools")
                tools_menu
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
                invalid_option "${#submsett[@]}"
                ;;
        esac
    done
}
function main_disconnect {
    heading "Disconnect"
    echo
    if [[ "$alwaysrate" =~ ^[Yy]$ ]]; then
        rate_server
    fi
    disconnect_vpn "force" "check_ks"
    status
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
    for program in wg jq curl figlet lolcat highlight speedtest-cli
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
function main_menu {
    if [[ "$1" == "start" ]]; then
        echo -e "${EIColor}Welcome to nordlist!${Color_Off}"
        echo
    elif [[ "$fast1" =~ ^[Yy]$ ]]; then
        echo
        #echo -e "${FColor}[F]ast1 is enabled.  Return to the Main Menu.${Color_Off}"
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
    COLUMNS=$menuwidth
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
    mainmenu=( "Vancouver" "Seattle" "Los_Angeles" "Denver" "Atlanta" "US_Cities" "CA_Cities" "P2P_Canada" "Discord" "QuickConnect" "Countries" "Groups" "Settings" "Disconnect" "Exit" )
    #
    select opt in "${mainmenu[@]}"
    do
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
            "Los_Angeles")
                main_header
                nordvpn connect Los_Angeles
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
                city_menu
                ;;
            "CA_Cities")
                # city menu for Canada
                xcountry="Canada"
                city_menu
                ;;
            "P2P_Canada")
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
            "QuickConnect")
                # alternative to "nordvpn connect"
                quick_connect
                ;;
            "Hostname")
                # can add to mainmenu
                # connect to specific server by name
                host_connect
                ;;
            "Random")
                # can add to mainmenu
                # connect to a random city worldwide
                random_worldwide
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
            "Disconnect")
                main_disconnect
                ;;
            "Exit")
                heading "Goodbye!"
                status
                break
                ;;
            *)
                invalid_option "${#mainmenu[@]}"
                main_menu
                ;;
        esac
    done
    exit
}
#
set_colors
echo
check_depends
echo
if (( BASH_VERSINFO < 4 )); then
    echo "Bash Version $BASH_VERSION"
    echo -e "${WColor}Bash v4.0 or higher is required.${Color_Off}"
    echo
    exit 1
fi
#
if (( "$nordvpn_exists" )); then
    nordvpn --version
    echo
else
    echo -e "${WColor}The NordVPN Linux client could not be found.${Color_Off}"
    echo "https://nordvpn.com/download/"
    echo
    exit 1
fi
#
if ! systemctl is-active --quiet nordvpnd; then
    echo -e "${WColor}nordvpnd.service is not active${Color_Off}"
    echo -e "${EColor}Starting the service... ${Color_Off}"
    echo "sudo systemctl start nordvpnd.service"
    sudo systemctl start nordvpnd.service; wait
    echo
fi
# Update notice "A new version of NordVPN is available! Please update the application."
if nordvpn status | grep -i "update"; then
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
#   delete: /var/lib/nordvpn    (should already be deleted)
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
#   nordvpn login --legacy
#   nordvpn login --username <username> --password <password>
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
#       Green = Connected, Red = Disconnected.  Screenshot:  https://i.imgur.com/fLOoyiJ.jpg
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
