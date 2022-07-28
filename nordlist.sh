#!/bin/bash
# shellcheck disable=SC2034,SC2129,SC2154
# unused color variables, individual redirects, var assigned
#
# Tested with NordVPN Version 3.14.1 on Linux Mint 20.3
# July 28, 2022
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added a
# lot of comments to help fellow newbies customize the script.
#
# Screenshots:
# https://i.imgur.com/dQhOPWH.png
# https://i.imgur.com/tlbAxaf.png
# https://i.imgur.com/EsaXIqY.png
# https://i.imgur.com/c31ZwqJ.png
#
# https://github.com/ph202107/nordlist
# /u/pennyhoard20 on reddit
# Suggestions/feedback welcome
#
# =====================================================================
# Instructions
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
#   "std_ascii" in "function logo"
#
# =====================================================================
# Other programs used:
#
# wireguard-tools  Settings-Tools-WireGuard     (function wireguard_gen)
# speedtest-cli    Settings-Tools-Speed Tests   (function fspeedtest)
# highlight        Settings-Script              (function fscriptinfo)
#
# eg.   "sudo apt install wireguard wireguard-tools"
#       "sudo apt install speedtest-cli highlight"
#
# For VPN On/Off status in the system tray, I use the Linux Mint
# Cinnamon applet "Bash Sensors".  The config is in the "Notes" below.
#
# =====================================================================
# Note: These functions require a sudo password:
#   - function frestart
#   - function fiptables
#   - function wireguard_gen
#   - function fcustomdns "Flush DNS Cache"
#
# =====================================================================
# CUSTOMIZATION
# (all of these are optional)
#
# When changing servers disconnect the VPN first, then connect to the
# new server.  "y" or "n"
disconnect="n"
#
# Specify your P2P preferred location.  Choose a Country or a City.
# eg  p2pwhere="Canada"  or  p2pwhere="Toronto"
p2pwhere=""
#
# Specify your Obfuscated_Servers location. Choose a Country or a City.
# The location must support obfuscation.
# eg  obwhere="United_States"  or  obwhere="Los_Angeles"
obwhere=""
#
# Specify your Auto-Connect location. Choose a Country or a City.
# eg  acwhere="Australia"  or  acwhere="Sydney"
# When obfuscate is enabled, the location must support obfuscation.
acwhere=""
#
# Specify your Custom DNS servers with a description.
# Can specify up to 3 IP addresses separated by a space.
#default_dns="192.168.1.70"; dnsdesc="PiHole"
default_dns="103.86.96.100 103.86.99.100"; dnsdesc="Nord"
#
# Specify a VPN hostname to use for testing while the VPN is off.
# Can still enter any hostname later, this is just a default choice.
default_host="ca1576.nordvpn.com"
#
# Specify any hostname to lookup when testing DNS response time.
# Can also enter a different hostname later.
dns_defhost="reddit.com"
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
# Open http links in a new Firefox window.  "y" or "n"
# Choose "n" to use the default browser or method.
usefirefox="n"
#
# Set 'menuwidth' to your terminal width or lower eg. menuwidth="70"
# Lowering the value will compact the menus horizontally.
# Leave blank to have the menu width change with the window size.
menuwidth=""
#
# =====================================================================
# FAST options speed up the script by automatically answering 'yes'
# to prompts.  Would recommend trying the script to see how it operates
# before enabling these options.
#
# Choose "y" or "n"
#
# Return to the main menu without prompting "Press any key..."
fast1="n"
#
# Automatically change these settings without prompting:
# Firewall, KillSwitch, TPLite, Notify, AutoConnect, IPv6
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
# Visual
# Change the main menu figlet ASCII style in "function custom_ascii"
# Change the figlet ASCII style for headings in "function heading"
# Change the text and indicator colors in "function colors"
#
# =====================================================================
# The Main Menu starts on line 3006 (function main_menu). Configure the
# first nine main menu items to suit your needs.
#
# Add your Whitelist commands to "function whitelist_commands"
# Set up a default NordVPN config in "function set_defaults"
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
    # - NordLynx is UDP only
    # - Obfuscate requires OpenVPN
    # - Kill Switch requires Firewall
    # - TPLite disables CustomDNS and vice versa
    # - Changing the Technology, Protocol, or Obfuscate setting requires a disconnect
    #
    # For each setting uncomment one of the two choices (or neither).
    #
    if [[ "$technology" == "openvpn" ]]; then nordvpn set technology nordlynx; set_vars; fi
    #if [[ "$technology" == "nordlynx" ]]; then nordvpn set technology openvpn; set_vars; fi
    #
    if [[ "$protocol" == "TCP" ]]; then nordvpn set protocol UDP; fi    # uppercase TCP
    #if [[ "$protocol" == "UDP" ]]; then nordvpn set protocol TCP; fi   # uppercase UDP
    #
    if [[ "$firewall" == "disabled" ]]; then nordvpn set firewall enabled; fi
    #if [[ "$firewall" == "enabled" ]]; then nordvpn set firewall disabled; fi
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
    #if [[ "$autocon" == "disabled" ]]; then nordvpn set autoconnect enabled $acwhere; fi
    if [[ "$autocon" == "enabled" ]]; then nordvpn set autoconnect disabled; fi
    #
    #if [[ "$ipversion6" == "disabled" ]]; then nordvpn set ipv6 enabled; fi
    if [[ "$ipversion6" == "enabled" ]]; then nordvpn set ipv6 disabled; fi
    #
    #if [[ "$meshnet" == "disabled" ]]; then nordvpn set meshnet enabled; fi
    #if [[ "$meshnet" == "enabled" ]]; then nordvpn set meshnet disabled; fi
    #
    #if [[ "$dns_set" == "disabled" ]]; then nordvpn set dns $default_dns; fi
    if [[ "$dns_set" != "disabled" ]]; then nordvpn set dns disabled; fi
    #
    echo
    echo -e "${LColor}Default configuration applied.${Color_Off}"
    echo
}
function std_ascii {
    # This ASCII can display above the main menu if you prefer to use
    # other ASCII art. Place any ASCII art between cat << "EOF" and EOF
    # and specify std_ascii in "function logo".
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
function custom_ascii {
    # This is the customized ASCII generated by figlet, displayed above the main menu.
    # Specify custom_ascii in "function logo".
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
function logo {
    set_vars
    if [[ "$1" != "stats" ]]; then
        #
        # Specify  std_ascii or custom_ascii on the line below.
        custom_ascii
        #
    fi
    echo -e "$connectedcl ${CIColor}$city ${COColor}$country ${SVColor}$server ${IPColor}$ipaddr ${Color_Off}"
    echo -e "$techpro$fw$ks$tp$ob$no$ac$ip6$mn$dns$wl$fst"
    echo -e "$transferc ${UPColor}$uptime ${Color_Off}"
    if [[ -n $transferc ]]; then echo; fi
    # all indicators: $techpro$fw$ks$tp$ob$no$ac$ip6$mn$dns$wl$fst
}
function heading {
    clear -x
    if ! (( "$figlet_exists" )) || ! (( "$lolcat_exists" )); then
        echo
        echo -e "${HColor}/// $1 ///${Color_Off}"
        echo
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
        echo -e "${HColor}/// $1 ///${Color_Off}"
        echo
    fi
    COLUMNS=$menuwidth
}
function colors {
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
    SColor=${BBlue}         # Color for the std_ascii image
    HColor=${BGreen}        # Non-figlet headings
    # logo
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
function nstatbl {
    # search "status" array by line (case insensitive)
    printf '%s\n' "${nstat[@]}" | grep -i "$1"
}
function nsetsbl {
    # search "settings" array by line (case insensitive)
    printf '%s\n' "${nsets[@]}" | grep -i "$1"
}
function set_vars {
    # Store info in arrays (BASH v4)
    readarray -t nstat < <( nordvpn status | tr -d '\r' )
    readarray -t nsets < <( nordvpn settings | tr -d '\r' | tr '[:upper:]' '[:lower:]' )
    #
    # "nordvpn status" - array nstat - search function nstatbl
    # When disconnected, $connected is the only variable from nstat
    connected=$(nstatbl "Status" | cut -f2 -d':' | cut -c 2- | tr '[:upper:]' '[:lower:]')
    nordhost=$(nstatbl "Current server" | cut -f3 -d' ')    # full hostname
    server=$(echo "$nordhost" | cut -f1 -d'.')              # shortened hostname
    # country and city names may have spaces
    country=$(nstatbl "Country" | cut -f2 -d':' | cut -c 2-)
    city=$(nstatbl "City" | cut -f2 -d':' | cut -c 2-)
    ip=$(nstatbl "Server IP" | cut -f 2-3 -d' ')            # includes "IP: "
    ipaddr=$(echo "$ip" | cut -f2 -d' ')                    # IP address only
    #technology2=$(nstatbl "technology" | cut -f3 -d' ')    # variable not used
    protocol2=$(nstatbl "protocol" | cut -f3 -d' ' | tr '[:lower:]' '[:upper:]')
    transferd=$(nstatbl "Transfer" | cut -f 2-3 -d' ')      # download stat with units
    transferu=$(nstatbl "Transfer" | cut -f 5-6 -d' ')      # upload stat with units
    #transfer="\u25bc $transferd  \u25b2 $transferu"        # unicode up/down arrows
    uptime=$(nstatbl "Uptime" | cut -f 1-5 -d' ')
    #
    # "nordvpn settings" - array nsets (all elements lowercase) - search function nsetsbl
    # $protocol and $obfuscate are not listed when using NordLynx
    technology=$(nsetsbl "Technology" | cut -f2 -d':' | cut -c 2-)
    protocol=$(nsetsbl "Protocol" | cut -f2 -d' ' | tr '[:lower:]' '[:upper:]')
    firewall=$(nsetsbl "Firewall" | cut -f2 -d' ')
    killswitch=$(nsetsbl "Kill" | cut -f3 -d' ')
    #tplite=$(printf '%s\n' "${nsets[@]}" | grep -i -E "CyberSec|Threat" | awk '{print $NF}')
    #tplite=$(nsetsbl "CyberSec" | cut -f2 -d' ')           # CyberSec (v3.13-)
    tplite=$(nsetsbl "Threat" | cut -f4 -d' ')              # Threat Protection Lite (v3.14+)
    obfuscate=$(nsetsbl "Obfuscate" | cut -f2 -d' ')
    notify=$(nsetsbl "Notify" | cut -f2 -d' ')
    autocon=$(nsetsbl "Auto" | cut -f2 -d' ')
    ipversion6=$(nsetsbl "IPv6" | cut -f2 -d' ')
    meshnet=$(nsetsbl "Meshnet" | cut -f2 -d' ' | tr -d '\n')
    dns_set=$(nsetsbl "DNS" | cut -f2 -d' ')                    # disabled or not=disabled
    dns_srvrs=$(nsetsbl "DNS" | tr '[:lower:]' '[:upper:]')     # Server IPs, includes "DNS: "
    whitelist=$( printf '%s\n' "${nsets[@]}" | grep -A100 -i "whitelist" )
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
    if [[ "$autocon" == "enabled" ]]; then
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
    if [[ "$dns_set" == "disabled" ]]; then # reversed
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
function disconnectvpn {
    # $1 = force a disconnect
    #
    echo
    if [[ "$disconnect" =~ ^[Nn]$ ]] && [[ "$1" != "force" ]]; then
        return
    fi
    set_vars
    if [[ "$connected" == "connected" ]]; then
        echo -e "${WColor}** Disconnect **${Color_Off}"
        echo
        nordvpn disconnect; wait
        echo
    fi
}
function ipinfobl {
    printf '%s\n' "${ipinfo[@]}" | grep -m1 -i "$1" | cut -f4 -d'"'
}
function getexternalip {
    echo -n "External IP: "
    readarray -t ipinfo < <( timeout 10 curl --silent ipinfo.io )
    extip=$( ipinfobl "ip" )
    exthost=$( ipinfobl "hostname" )
    extorg=$( ipinfobl "org" )
    extcity=$( ipinfobl "city" )
    extregion=$( ipinfobl "region" )
    extcountry=$( ipinfobl "country" )
    extlimit=$( ipinfobl "rate limit" )
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
        logo
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
        getexternalip
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
}
function warning {
    set_vars
    if [[ "$connected" == "connected" ]]; then
        echo -e "${WColor}** Changing this setting will disconnect the VPN **${Color_Off}"
        echo
    fi
}
function openlink {
    # $1 = URL or link to open
    # $2 = ask first
    # $3 = exit after opening
    #
    if [[ "$2" == "ask" ]]; then
        read -n 1 -r -p "$(echo -e "Open ${EColor}$1${Color_Off} ? (y/n) ")"; echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    if [[ "$1" == *"http"* ]] && [[ "$usefirefox" =~ ^[Yy]$ ]]; then
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
function fcountries {
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
            cities
        elif (( 1 <= REPLY )) && (( REPLY <= numcountries )); then
            cities
        else
            invalid_option "$numcountries"
        fi
    done
}
function cities {
    # all available cities in $xcountry
    heading "$xcountry"
    echo
    if [[ "$xcountry" == "Sarajevo" ]]; then  # special case
        xcountry="Bosnia_and_Herzegovina"
        echo -e "${HColor}/// $xcountry ///${Color_Off}"
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
        echo -e "Connecting to ${LColor}${citylist[0]}${Color_Off}."
        echo
        disconnectvpn
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
            disconnectvpn
            echo "Connecting to the best available city."
            echo
            nordvpn connect "$xcountry"
            status
            exit
        elif [[ "$xcity" == "Random" ]]; then
            heading "$rcity"
            echo
            echo "Random choice = $rcity"
            disconnectvpn
            echo "Connecting to $rcity $xcountry"
            echo
            nordvpn connect "$rcity"
            status
            exit
        elif (( 1 <= REPLY )) && (( REPLY <= numcities )); then
            heading "$xcity"
            disconnectvpn
            echo "Connecting to $xcity $xcountry"
            echo
            nordvpn connect "$xcity"
            status
            exit
        else
            invalid_option "$numcities"
        fi
    done
}
function fhostname {
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
    echo "Leave blank to quit."
    read -r -p "Enter the server name (eg. us9364): " specsrvr
    if [[ -z $specsrvr ]]; then
        echo -e "${DColor}(Skipped)${Color_Off}"
        echo
        return
    elif [[ "$specsrvr" == *"socks"* ]]; then
        echo
        echo -e "${WColor}Unable to connect to SOCKS servers${Color_Off}"
        echo
        return
    elif [[ "$specsrvr" == *"nord"* ]]; then
        specsrvr=$( echo "$specsrvr" | cut -f1 -d'.' )
    fi
    disconnectvpn
    echo "Connect to $specsrvr"
    echo
    nordvpn connect "$specsrvr"
    status
    # add testing commands here
    #
    # https://streamtelly.com/check-netflix-region/
    # echo "Netflix Region and Status"
    # curl --silent "http://api-global.netflix.com/apps/applefuji/config" | grep -E 'geolocation.country|geolocation.status'
    # echo
}
function ffullrandom {
    # connect to a random city worldwide
    #
    create_list "country"
    xcountry="$rcountry"
    create_list "city"
    #
    heading "Random"
    disconnectvpn
    echo "Connect to $rcity $rcountry"
    echo
    nordvpn connect "$rcity"
    status
    exit
}
function killswitch_groups {
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
            change_setting "killswitch" "override"
        fi
    fi
}
function fobservers {
    # Not available with NordLynx
    heading "Obfuscated"
    echo "Obfuscated servers are specialized VPN servers that"
    echo "hide the fact that you’re using a VPN to reroute your"
    echo "traffic. They allow users to connect to a VPN even in"
    echo "heavily restrictive environments."
    echo
    echo -e "Current settings: $techpro$fw$ks$ob"
    echo
    echo "To connect to the Obfuscated_Servers group the"
    echo "following changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    echo "Set Technology to OpenVPN."
    echo "Specify the Protocol."
    echo "Set Obfuscate to enabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Obfuscated_Servers group $obwhere"
    echo -e "${Color_Off}"
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "; echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnectvpn "force"
        if [[ "$technology" == "nordlynx" ]]; then
            nordvpn set technology openvpn; wait
            echo
            # ask_protocol will update $protocol and $obfuscate
        fi
        ask_protocol
        if [[ "$obfuscate" == "disabled" ]]; then
            nordvpn set obfuscate enabled; wait
            echo
        fi
        killswitch_groups
        echo -e "Connect to the Obfuscated_Servers group ${LColor}$obwhere${Color_Off}"
        echo
        nordvpn connect --group Obfuscated_Servers $obwhere
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function fdoublevpn {
    # Not available with obfuscate enabled
    heading "Double-VPN"
    echo "Double VPN is a privacy solution that sends your internet"
    echo "traffic through two VPN servers, encrypting it twice."
    echo
    echo -e "Current settings: $techpro$fw$ks$ob"
    echo
    echo "To connect to the Double_VPN group the"
    echo "following changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    echo "Choose the Technology & Protocol."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Double_VPN group."
    echo -e "${Color_Off}"
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "; echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnectvpn "force"
        ftechnology "back"
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
            echo
        fi
        killswitch_groups
        echo "Connect to the Double_VPN group."
        echo
        nordvpn connect --group Double_VPN
        # nordvpn connect --group Double_VPN <country_code>
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function fonion {
    # Not available with obfuscate enabled
    heading "Onion+VPN"
    echo "Onion over VPN is a privacy solution that sends your "
    echo "internet traffic through a VPN server and then"
    echo "through the Onion network."
    echo
    echo -e "Current settings: $techpro$fw$ks$ob"
    echo
    echo "To connect to the Onion_Over_VPN group the"
    echo "following changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    echo "Choose the Technology & Protocol."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Onion_Over_VPN group."
    echo -e "${Color_Off}"
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "; echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnectvpn "force"
        ftechnology "back"
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
            echo
        fi
        killswitch_groups
        echo "Connect to the Onion_Over_VPN group."
        echo
        nordvpn connect --group Onion_Over_VPN
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function fp2p {
    # P2P not available with obfuscate enabled
    heading "Peer to Peer"
    echo "Peer to Peer - sharing information and resources directly"
    echo "without relying on a dedicated central server."
    echo
    echo -e "Current settings: $techpro$fw$ks$ob"
    echo
    echo "To connect to the P2P group the following"
    echo "changes will be made (if necessary):"
    echo -e "${LColor}"
    echo "Disconnect the VPN."
    echo "Choose the Technology & Protocol."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the P2P group $p2pwhere"
    echo -e "${Color_Off}"
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "; echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnectvpn "force"
        ftechnology "back"
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
            echo
        fi
        killswitch_groups
        echo -e "Connect to the P2P group ${LColor}$p2pwhere${Color_Off}"
        echo
        nordvpn connect --group P2P $p2pwhere
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function ftechnology {
    heading "Technology"
    echo
    warning
    echo "OpenVPN is an open-source VPN protocol and is required to"
    echo " use Obfuscated servers and to use TCP."
    echo "NordLynx is built around the WireGuard VPN protocol"
    echo " and may be faster with less overhead."
    echo
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
        disconnectvpn "force"
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
            ask_protocol
        fi
    else
        echo
        echo -e "Continue to use $technologydc."
    fi
    if [[ "$1" == "back" ]]; then
        echo
        set_vars
        return
    fi
    main_menu
}
function fprotocol {
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
            ftechnology
        fi
    else
        warning
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
            disconnectvpn "force"
            if [[ "$protocol" == "UDP" ]]; then
                nordvpn set protocol TCP; wait
            else
                nordvpn set protocol UDP; wait
            fi
        else
            echo
            echo -e "Continue to use $protocoldc."
        fi
    fi
    main_menu
}
function ask_protocol {
    # Ask to choose TCP/UDP if changing to OpenVPN, using Obfuscate,
    # and when connecting to the Obfuscated Servers group
    #
    # set $protocol if technology just changed from NordLynx
    set_vars
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
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnectvpn "force"
        if [[ "$protocol" == "UDP" ]]; then
            nordvpn set protocol TCP; wait
        else
            nordvpn set protocol UDP; wait
        fi
        echo
    else
        echo
        echo -e "Continue to use $protocoldc."
        echo
    fi
}
function change_setting {
    # $1 = Nord command
    # $2 = override fast2 and main_menu
    #
    chgloc=""
    case "$1" in
        "firewall")
            chgname="the Firewall"; chgvar="$firewall"; chgind="$fw"
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
            chgname="Auto-Connect"; chgvar="$autocon"; chgind="$ac"; chgloc="$acwhere"
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
    if [[ "$fast2" =~ ^[Yy]$ ]] && [[ "$2" != "override" ]]; then
        echo -e "${FColor}[F]ast2 is enabled.  Changing the setting.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "$chgprompt"; echo
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$chgvar" == "disabled" ]]; then
            if [[ "$1" == "killswitch" ]] && [[ "$firewall" == "disabled" ]]; then
                # when connecting to Groups or changing the setting from IPTables
                echo -e "${WColor}Enabling the Firewall.${Color_Off}"
                echo
                nordvpn set firewall enabled; wait
                echo
            elif [[ "$1" == "threatprotectionlite" ]] && [[ "$dns_set" != "disabled" ]]; then
                nordvpn set dns disabled; wait
                echo
            elif [[ "$1" == "autoconnect" ]] && [[ -n $acwhere ]]; then
                echo -e "$chgname to ${LColor}$chgloc${Color_Off}"
                echo
            elif [[ "$1" == "meshnet" ]]; then
                echo -e "${WColor}Wait 30s to refresh the peer list.${Color_Off}"
                echo
            fi
            nordvpn set "$1" enabled $chgloc; wait
        else
            if [[ "$1" == "firewall" ]] && [[ "$killswitch" == "enabled" ]]; then
                # when changing the setting from IPTables
                echo -e "${WColor}Disabling the Kill Switch.${Color_Off}"
                echo
                nordvpn set killswitch disabled; wait
                echo
            fi
            nordvpn set "$1" disabled; wait
        fi
    else
        echo -e "$chgind Keep $chgname $chgvarc."
    fi
    if [[ "$2" == "override" ]]; then
        echo
        return
    fi
    main_menu
}
function ffirewall {
    heading "Firewall"
    echo "Enable or Disable the NordVPN Firewall."
    echo "Enabling the Nord Firewall disables the Linux UFW."
    echo "The Firewall must be enabled to use the Kill Switch."
    echo
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "$fw the Firewall is $firewallc."
        echo
        echo -e "${WColor}The Kill Switch must be disabled before disabling the Firewall.${Color_Off}"
        echo
        change_setting "killswitch" "override"
        set_vars
        if [[ "$killswitch" == "enabled" ]]; then
            echo -e "$fw Keep the Firewall $firewallc."
            main_menu
        fi
    fi
    change_setting "firewall"
}
function fkillswitch {
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
        change_setting "firewall" "override"
        set_vars
        if [[ "$firewall" == "disabled" ]]; then
            echo -e "$ks Keep the Kill Switch $killswitchc."
            main_menu
        fi
    fi
    change_setting "killswitch"
}
function ftplite {
    heading "TPLite"
    echo "Threat Protection Lite is a feature protecting you"
    echo "from ads, unsafe connections, and malicious sites."
    echo "Previously known as 'CyberSec'."
    echo
    echo -e "Enabling TPLite disables Custom DNS $dns"
    if [[ "$dns_set" != "disabled" ]]; then
        echo "Current $dns_srvrs"
    fi
    echo
    change_setting "threatprotectionlite"
}
function fnotify {
    heading "Notify"
    echo
    echo "Send OS notifications when the VPN status changes."
    echo
    change_setting "notify"
}
function fautoconnect {
    heading "AutoConnect"
    echo "Automatically connect to the VPN on startup."
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob When obfuscate is enabled, the Auto-Connect"
        echo "     location must support obfuscation."
        echo
    fi
    if [[ "$autocon" == "disabled" ]] && [[ -n $acwhere ]]; then
        echo -e "Auto-Connect location: ${LColor}$acwhere${Color_Off}"
        echo
    fi
    change_setting "autoconnect"
}
function fipversion6 {
    # May 2022 - IPv6 capable servers:  us9591 us9592 uk1875 uk1876
    heading "IPv6"
    echo "Enable or disable NordVPN IPv6 support."
    echo
    change_setting "ipv6"
}
function fobfuscate {
    # Obfuscate not available when using NordLynx
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
            ftechnology "back"
            fobfuscate
        fi
    else
        warning
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
        if [[ "$obfuscate" == "enabled" ]]; then
            obprompt=$(echo -e "${DColor}Disable${Color_Off} Obfuscate? (y/n) ")
        else
            obprompt=$(echo -e "${EColor}Enable${Color_Off} Obfuscate? (y/n) ")
        fi
        if [[ "$fast3" =~ ^[Yy]$ ]]; then
            echo -e "${FColor}[F]ast3 is enabled.  Changing the setting.${Color_Off}"
            REPLY="y"
        else
            read -n 1 -r -p "$obprompt"; echo
        fi
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            disconnectvpn "force"
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
            else
                nordvpn set obfuscate enabled; wait
            fi
            echo
            ask_protocol
        else
            echo
            echo -e "$ob Keep Obfuscate $obfuscatec."
        fi
    fi
    main_menu
}
function fmeshnet {
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
    submesh=("Enable/Disable" "Peer List" "Peer Refresh" "Peer Remove" "Peer Incoming" "Peer Routing" "Peer Connect" "Invite List" "Invite Send" "Invite Accept" "Invite Deny" "Invite Revoke" "Support" "Exit")
    select mesh in "${submesh[@]}"
    do
        case $mesh in
            "Enable/Disable")
                echo
                change_setting "meshnet" "override"
                set_vars
                fmeshnet
                ;;
            "Peer List")
                echo
                echo -e "${EColor}== Peer List ==${Color_Off}"
                echo "Lists available peers in a meshnet."
                echo "'nordvpn meshnet peer list'"
                echo
                nordvpn meshnet peer list
                ;;
            "Peer Refresh")
                echo
                echo -e "${EColor}== Peer Refresh ==${Color_Off}"
                echo "Refreshes the meshnet in case it was not updated automatically."
                echo "'nordvpn meshnet peer refresh'"
                echo
                nordvpn meshnet peer refresh
                ;;
            "Peer Remove")
                echo
                echo -e "${EColor}== Peer Remove ==${Color_Off}"
                echo "Removes a peer from the meshnet."
                echo
                echo "Enter the public_key, hostname, or IP address."
                echo "(Leave blank to quit)"
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
                echo
                echo -e "${EColor}== Peer Incoming ==${Color_Off}"
                echo "Peers under the same account are automatically added to the meshnet."
                echo "Allow or Deny a meshnet peer's incoming traffic to this device."
                echo
                echo "Usage: nordvpn meshnet peer incoming [command options] [public_key|hostname|ip]"
                echo "Options:"
                echo " allow - Allows a meshnet peer to send traffic to this device."
                echo " deny  - Denies a meshnet peer to send traffic to this device."
                echo
                echo "Enter 'allow' or 'deny' and the public_key, hostname, or ip"
                echo "(Leave blank to quit)"
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
                echo
                echo -e "${EColor}== Peer Routing ==${Color_Off}"
                echo "Allow or Deny a meshnet peer routing traffic through this device."
                echo
                echo "Usage: nordvpn meshnet peer routing [command options] [public_key|hostname|ip]"
                echo "Options:"
                echo " allow - Allows a meshnet peer to route its' traffic through this device."
                echo " deny  - Denies a meshnet peer to route its' traffic through this device."
                echo
                echo "Enter 'allow' or 'deny' and the public_key, hostname, or ip"
                echo "(Leave blank to quit)"
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
            "Peer Connect")
                echo
                echo -e "${EColor}== Peer Connect ==${Color_Off}"
                echo "Treats a peer as a VPN server and connects to it if the"
                echo " peer has allowed traffic routing."
                echo
                echo "Enter the public_key, hostname, or IP address."
                echo "(Leave blank to quit)"
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
                echo
                echo -e "${LColor}== Invite List ==${Color_Off}"
                echo "Displays the list of all sent and received meshnet invitations."
                echo "'nordvpn meshnet invite list'"
                echo
                nordvpn meshnet invite list
                ;;
            "Invite Send")
                echo
                echo -e "${LColor}== Invite Send ==${Color_Off}"
                echo "Sends an invitation to join the mesh network."
                echo
                echo "Usage: nordvpn meshnet invite send [command options] [email]"
                echo "Options:"
                echo " --allow-incoming-traffic  Allow incomming traffic from a peer. (default: false)"
                echo " --allow-traffic-routing   Allow the peer to route traffic through this device. (default: false)"
                echo
                echo "(Leave blank to quit)"
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
                echo
                echo -e "${LColor}== Invite Accept ==${Color_Off}"
                echo "Accepts an invitation to join the inviter's mesh network."
                echo
                echo "Usage: nordvpn meshnet invite accept [command options] [email]"
                echo "Options:"
                echo " --allow-incoming-traffic  Allow incomming traffic from the peer. (default: false)"
                echo " --allow-traffic-routing   Allow the peer to route traffic through this device. (default: false)"
                echo
                echo "(Leave blank to quit)"
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
                echo
                echo -e "${LColor}== Invite Deny ==${Color_Off}"
                echo "Denies an invitation to join the inviter's mesh network."
                echo
                echo "Enter the email address to deny."
                echo "(Leave blank to quit)"
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
                echo
                echo -e "${LColor}== Invite Revoke ==${Color_Off}"
                echo "Revokes a sent invitation."
                echo
                echo "Enter the email address to revoke."
                echo "(Leave blank to quit)"
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
                echo
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
function fcustomdns {
    heading "CustomDNS"
    echo "The NordVPN app automatically uses NordVPN DNS servers"
    echo "to prevent DNS leaks. (103.86.96.100 and 103.86.99.100)"
    echo "You can specify your own Custom DNS servers instead."
    echo
    echo -e "Enabling Custom DNS disables TPLite $tp"
    echo
    if [[ "$dns_set" == "disabled" ]]; then
        echo -e "$dns Custom DNS is ${DColor}disabled${Color_Off}."
    else
        echo -e "$dns Custom DNS is ${EColor}enabled${Color_Off}."
        echo "Current $dns_srvrs"
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
                read -r -p "Hit 'Enter' for [$dns_defhost]: " testhost
                testhost=${testhost:-$dns_defhost}
                echo; echo -e "${EColor}dig @<DNS> $testhost${Color_Off}"
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
function fwhitelist {
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
    echo -e "${LColor}whitelist_commands${Color_Off}"
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
    echo
    echo "For now, users without a GUI can use "
    echo -e "${LColor}      nordvpn login --legacy${Color_Off}"
    echo -e "${LColor}      nordvpn login --username <username> --password <password>${Color_Off}"
    echo
    echo -e "${WColor}If you don't have a web browser on the device:${Color_Off}"
    echo -e "${LColor}Nord Account login without a GUI ('man nordvpn' Note 2)${Color_Off}"
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
function faccount {
    heading "Account"
    echo
    PS3=$'\n''Choose an Option: '
    submacct=("Login (legacy)" "Login (browser)" "Login (no GUI)" "Logout" "Account Info" "Register" "Nord Version" "Changelog" "Nord Manual" "Support" "Exit")
    select acc in "${submacct[@]}"
    do
        case $acc in
            "Login (legacy)")
                echo
                nordvpn login --legacy
                echo
                ;;
            "Login (browser)")
                echo
                nordvpn login
                echo
                ;;
            "Login (no GUI)")
                login_nogui
                ;;
            "Logout")
                disconnectvpn "force"
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
                    disconnectvpn "force"
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
                echo
                echo -e "${LColor}Support${Color_Off}"
                echo "email: support@nordvpn.com"
                echo "https://support.nordvpn.com/"
                echo "https://nordvpn.com/contact-us/"
                echo
                echo -e "${LColor}Direct link to online chat${Color_Off}"
                echo "https://v2.zopim.com/widget/popout.html?key=oxKZnmXv4KZ1uFO78i56rMEovdYXH2jm"
                echo
                echo -e "${LColor}Terms of Service${Color_Off}"
                echo "https://my.nordaccount.com/legal/terms-of-service/"
                echo
                echo -e "${LColor}Privacy Policy${Color_Off}"
                echo "https://my.nordaccount.com/legal/privacy-policy/"
                echo
                echo -e "${LColor}Warrant Canary (bottom of page)${Color_Off}"
                echo "https://nordvpn.com/security-efforts/"
                echo
                echo -e "${LColor}Bug Bounty${Color_Off}"
                echo "https://hackerone.com/nordsecurity?type=team"
                echo
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
function frestart {
    heading "Restart"
    echo
    echo "Restart nordvpn services."
    echo -e "${WColor}"
    echo "Send commands:"
    echo "nordvpn set killswitch disabled (choice)"
    echo "nordvpn set autoconnect disabled (choice)"
    echo "sudo systemctl restart nordvpnd.service"
    echo "sudo systemctl restart nordvpn.service"
    echo -e "${Color_Off}"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$killswitch" == "enabled" ]]; then
            change_setting "killswitch" "override"
        fi
        if [[ "$autocon" == "enabled" ]]; then
            change_setting "autoconnect" "override"
        fi
        echo -e "${LColor}sudo systemctl restart nordvpnd.service${Color_Off}"
        echo -e "${LColor}sudo systemctl restart nordvpn.service${Color_Off}"
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
        if [[ "$1" == "plusdefaults" ]]; then
            echo
            nordvpn login
            wait
            read -n 1 -r -p "Press any key after login is complete... "; echo
            echo
            fdefaults
        fi
        status
        exit
    fi
    main_menu
}
function freset {
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
        disconnectvpn "force"
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
        read -n 1 -s -r -p "Press any key to restart services..."; echo
        set_vars
        frestart "plusdefaults"
    fi
    main_menu
}
function fiptables_status {
    echo
    set_vars
    echo -e "The VPN is $connectedc.  ${IPColor}$ip${Color_Off}"
    echo -e "$fw The Firewall is $firewallc."
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
function fiptables {
    # https://old.reddit.com/r/nordvpn/comments/qgakq9/linux_killswitch_problems_iptables/
    # * changes in version 3.13.0 - "We made changes in firewall handling. Now we filter packets by firewall marks instead of IP addresses of VPN servers."
    heading "IPTables"
    echo "Flushing the IPTables may help resolve problems enabling or"
    echo "disabling the KillSwitch or with other connection issues."
    echo -e "${WColor}"
    echo "** WARNING **"
    echo "  - This will CLEAR all of your Firewall rules"
    echo "  - Review 'function fiptables' before use"
    echo "  - Commands require 'sudo'"
    echo -e "${Color_Off}"
    PS3=$'\n''Choose an option: '
    submipt=("View IPTables" "Firewall" "KillSwitch" "Meshnet" "Whitelist" "Flush IPTables" "Restart Services" "ping google" "Disconnect" "Exit")
    select smipt in "${submipt[@]}"
    do
        case $smipt in
            "View IPTables")
                fiptables_status
                ;;
            "Firewall")
                echo
                set_vars
                change_setting "firewall" "override"
                fiptables_status
                ;;
            "KillSwitch")
                echo
                set_vars
                change_setting "killswitch" "override"
                fiptables_status
                ;;
            "Meshnet")
                echo
                set_vars
                change_setting "meshnet" "override"
                fiptables_status
                ;;
            "Whitelist")
                echo
                fwhitelist "back"
                fiptables_status
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
                    echo -e "${LColor}IPTables After:${Color_Off}"
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
                    if [[ "$autocon" == "enabled" ]]; then
                        change_setting "autoconnect" "override"
                    fi
                    disconnectvpn "force"
                    echo -e "${LColor}Restart NordVPN services. Wait 10s${Color_Off}"
                    echo
                    sudo systemctl restart nordvpnd.service
                    sudo systemctl restart nordvpn.service
                    for t in {10..1}; do
                        echo -n "$t "; sleep 1
                    done
                    echo
                    fiptables_status
                    echo -e "${LColor}ping -c 3 google.com${Color_Off}"
                    ping -c 3 google.com
                    echo
                else
                    echo
                    echo "No changes made."
                    echo
                fi
                ;;
            "ping google")
                fiptables_status
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
                        disconnectvpn "force"
                    fi
                fi
                fiptables_status
                ;;
            "Exit")
                sudo -K     # timeout sudo
                main_menu
                ;;
            *)
                invalid_option "${#submipt[@]}"
                ;;
        esac
    done
}
function rate_server {
    echo
    while true
    do
        echo "How would you rate your connection quality?"
        echo -e "${DColor}Terrible${Color_Off} <_1__2__3__4__5_> ${EColor}Excellent${Color_Off}"
        echo
        read -n 1 -r -p "$(echo -e "Rating 1-5 [e${LColor}x${Color_Off}it]: ")" rating
        if [[ $rating =~ ^[Xx]$ ]] || [[ -z $rating ]]; then
            echo -e "${DColor}(Skipped)${Color_Off}"; echo
            break
        elif (( 1 <= rating )) && (( rating <= 5 )); then
            echo; echo
            nordvpn rate "$rating"
            echo
            break
        else
            echo; echo
            echo -e "${WColor}** Please choose a number from 1 to 5"
            echo -e "('Enter' or 'x' to exit)${Color_Off}"
            echo
        fi
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
function allvpnservers {
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
    select smavpn in "${submallvpn[@]}"
    do
        case $smavpn in
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
                fhostname
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
                nordapi
                ;;
            *)
                invalid_option "${#submallvpn[@]}"
                ;;
        esac
    done
}
function nordapi {
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
    select sma in "${submapi[@]}"
    do
        case $sma in
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
                allvpnservers
                ;;
            "Change Host")
                change_host
                ;;
            "Connect")
                fhostname
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
    read -r -p "'Enter' for default [$default_host]: " nordhost
    nordhost=${nordhost:-$default_host}
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
        echo; echo -e "${WColor}$wgfull already exists${Color_Off}"
        echo; openlink "$wgfull" "ask"
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
function fspeedtest {
    heading "SpeedTests"
    echo
    logo "stats"
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
    speedtools=( "Download & Upload" "Download Only" "Upload Only" "Latency & Load" "speedtest.net"  "speedof.me" "fast.com" "linode.com" "digitalocean.com" "nperf.com" "Exit" )
    select spd in "${speedtools[@]}"
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
                    read -r -p "Enter a Hostname/IP [Default $default_host]: " nordhost
                    nordhost=${nordhost:-$default_host}
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
                        getexternalip
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
                ftools
                ;;
            *)
                invalid_option "${#speedtools[@]}"
                ;;
        esac
    done
}
function ftools {
    heading "Tools"
    if [[ "$connected" == "connected" ]]; then
        logo "stats"
        PS3=$'\n''Choose an option: '
    else
        echo -e "(VPN $connectedc)"
        read -r -p "Enter a Hostname/IP [Default $default_host]: " nordhost
        nordhost=${nordhost:-$default_host}
        echo
        echo -e "Hostname: ${LColor}$nordhost${Color_Off}"
        echo "(Does not affect 'Rate VPN Server')"
        echo
        PS3=$'\n''Choose an option (VPN Off): '
    fi
    nettools=( "NordVPN API" "External IP" "WireGuard" "Speed Tests" "Rate VPN Server" "ping vpn" "ping google" "my traceroute" "ipleak.net" "dnsleaktest.com" "test-ipv6.com" "ipx.ac" "ipinfo.io" "locatejs.com" "browserleaks.com" "bash.ws" "world map" "Change Host" "Exit" )
    select tool in "${nettools[@]}"
    do
        case $tool in
            "NordVPN API")
                nordapi
                ;;
            "External IP")
                echo
                getexternalip
                ;;
            "WireGuard")
                wireguard_gen
                ;;
            "Speed Tests")
                fspeedtest
                ;;
            "Rate VPN Server")
                rate_server
                ;;
            "ping vpn")
                echo
                echo -e "${LColor}ping -c 5 $nordhost${Color_Off}"
                echo
                ping -c 5 "$nordhost"
                echo
                ;;
            "ping google")
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
            "my traceroute")
                echo
                read -r -p "Destination [Default: $nordhost]: " target
                target=${target:-$nordhost}
                echo
                mtr "$target"
                ;;
            "ipleak.net")
                openlink "https://ipleak.net/"
                ;;
            "dnsleaktest.com")
                openlink "https://dnsleaktest.com/"
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
            "world map")
                # may be possible to highlight location
                echo
                echo -e "${LColor}OpenStreetMap ASCII World Map${Color_Off}"
                echo "- arrow keys to navigate"
                echo "- 'a' and 'z' to zoom"
                echo "- 'q' to quit"
                echo
                read -n 1 -r -p "telnet mapscii.me? (y/n) "; echo
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    telnet mapscii.me
                fi
                echo
                ;;
            "Change Host")
                change_host
                ;;
            "Exit")
                main_menu
                ;;
            *)
                invalid_option "${#nettools[@]}"
                ;;
        esac
    done
}
function fdefaults {
    defaultsc="${LColor}[Defaults]${Color_Off}"'\n'
    echo
    echo -e "$defaultsc  Disconnect and apply the NordVPN settings"
    echo "  specified in 'function set_defaults'"
    echo
    read -n 1 -r -p "Proceed? (y/n) "; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disconnectvpn "force"
        set_defaults
        read -n 1 -r -p "$(echo -e "$defaultsc  Go to the 'Whitelist' setting? (y/n) ")"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fwhitelist "back"
        fi
        echo
        read -n 1 -r -p "$(echo -e "$defaultsc  Go to the 'CustomDNS' setting? (y/n) ")"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            set_vars
            fcustomdns
        fi
        main_menu
    fi
}
function fscriptinfo {
    echo
    echo "$0"
    echo
    startline=$(grep -m1 -n "CUSTOM" "$0" | cut -f1 -d':')
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
function fquickconnect {
    # This is an alternate method of connecting to the NordVPN recommended server.
    # In some cases it may be faster than using "nordvpn connect"
    # Can disconnect (if KillSwitch is disabled) to find the nearest best server.
    # Requires 'curl' and 'jq'
    # Auguss82 via github
    heading "QuickConnect"
    if [[ "$killswitch" == "disabled" ]]; then
        # will disconnect if "disconnect=y"
        disconnectvpn
    fi
    echo
    echo "Getting the recommended server... "
    echo
    if [[ "$killswitch" == "enabled" ]] && [[ "$connected" != "connected" ]]; then
        echo -e "The VPN is $connectedc with the Kill Switch $killswitchc."
        echo
        bestserver=""
    elif [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Obfuscate is $obfuscatec."
        echo
        bestserver=""
    else
        bestserver="$(timeout 10 curl --silent 'https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations' | jq --raw-output '.[0].hostname' | awk -F. '{print $1}')"
    fi
    if [[ -z $bestserver ]]; then
        echo "Request timed out. Using 'nordvpn connect'"
        echo
        nordvpn connect
    else
        echo -e "Connecting to ${LColor}$bestserver${Color_Off}"
        echo
        nordvpn connect "$bestserver"
    fi
    status
    exit
}
function fgroups_all {
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
            disconnectvpn
            echo "Connecting to $xgroup."
            echo
            nordvpn connect --group "$xgroup"
            status
            exit
        else
            invalid_option "$numgroups"
        fi
    done
}
function fgroups {
    heading "Groups"
    echo
    PS3=$'\n''Choose a Group: '
    submgroups=("All_Groups" "Obfuscated" "Double-VPN" "Onion+VPN" "P2P" "Exit")
    select smg in "${submgroups[@]}"
    do
        case $smg in
            "All_Groups")
                fgroups_all
                ;;
            "Obfuscated")
                fobservers
                ;;
            "Double-VPN")
                fdoublevpn
                ;;
            "Onion+VPN")
                fonion
                ;;
            "P2P")
                fp2p
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
function fsettings {
    heading "Settings"
    echo
    echo -e "$techpro$fw$ks$tp$ob$no$ac$ip6$mn$dns$wl$fst"
    echo
    PS3=$'\n''Choose a Setting: '
    submsett=("Technology" "Protocol" "Firewall" "KillSwitch" "TPLite" "Obfuscate" "Notify" "AutoConnect" "IPv6" "Meshnet" "Custom-DNS" "Whitelist" "Account" "Restart" "Reset" "IPTables" "Tools" "Script" "Defaults" "Exit")
    select sms in "${submsett[@]}"
    do
        case $sms in
            "Technology")
                ftechnology
                ;;
            "Protocol")
                fprotocol
                ;;
            "Firewall")
                ffirewall
                ;;
            "KillSwitch")
                fkillswitch
                ;;
            "TPLite")
                ftplite
                ;;
            "Obfuscate")
                fobfuscate
                ;;
            "Notify")
                fnotify
                ;;
            "AutoConnect")
                fautoconnect
                ;;
            "IPv6")
                fipversion6
                ;;
            "Meshnet")
                fmeshnet
                ;;
            "Custom-DNS")
                fcustomdns
                ;;
            "Whitelist")
                fwhitelist
                ;;
            "Account")
                faccount
                ;;
            "Restart")
                frestart
                ;;
            "Reset")
                freset
                ;;
            "IPTables")
                fiptables
                ;;
            "Tools")
                ftools
                ;;
            "Script")
                fscriptinfo
                ;;
            "Defaults")
                fdefaults
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
function fdisconnect {
    heading "Disconnect"
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "${WColor}** Reminder **${Color_Off}"
        change_setting "killswitch" "override"
    fi
    if [[ "$alwaysrate" =~ ^[Yy]$ ]]; then
        rate_server
    fi
    disconnectvpn "force"
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
function mm_checkd {
    # Disconnection options for typical main menu connection
    # $1 = Force a disconnect regardless of setting "disconnect=y/n"
    # $2 = Apply default settings after forced disconnection
    #
    heading "$opt"
    if [[ "$1" == "force" ]]; then
        disconnectvpn "force"
        if [[ "$2" == "defaults" ]]; then
            set_defaults
        fi
    else
        disconnectvpn       # will only disconnect if "disconnect=y"
    fi
    echo "Connect to $opt"
    echo
}
function main_menu {
    if [[ "$1" == "start" ]]; then
        echo -e "${HColor}Welcome to nordlist!${Color_Off}"
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
    logo
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
                mm_checkd
                nordvpn connect Vancouver
                status
                break
                ;;
            "Seattle")
                mm_checkd
                nordvpn connect Seattle
                status
                break
                ;;
            "Los_Angeles")
                mm_checkd
                nordvpn connect Los_Angeles
                status
                break
                ;;
            "Denver")
                mm_checkd
                nordvpn connect Denver
                status
                break
                ;;
            "Atlanta")
                mm_checkd
                nordvpn connect Atlanta
                status
                break
                ;;
            "US_Cities")
                # city menu for United_States
                xcountry="United_States"
                cities
                ;;
            "CA_Cities")
                # city menu for Canada
                xcountry="Canada"
                cities
                ;;
            "P2P_Canada")
                # force a disconnect and apply default settings
                mm_checkd "force" "defaults"
                nordvpn connect --group p2p Canada
                status
                break
                ;;
            "Discord")
                # I use this entry to connect to a specific server which can help
                # avoid repeat authentication requests. It then opens a URL.
                # It may be useful for other sites or applications.
                # Example: NordVPN discord  https://discord.gg/83jsvGqpGk
                mm_checkd
                nordvpn connect us8247
                status
                openlink "https://discord.gg/83jsvGqpGk"
                break
                ;;
            "QuickConnect")
                # alternative to "nordvpn connect"
                fquickconnect
                ;;
            "Hostname")
                # can add to mainmenu
                # connect to specific server by name
                fhostname
                ;;
            "Random")
                # can add to mainmenu
                # connect to a random city worldwide
                ffullrandom
                ;;
            "Countries")
                fcountries
                ;;
            "Groups")
                fgroups
                ;;
            "Settings")
                fsettings
                ;;
            "Disconnect")
                fdisconnect
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
colors
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
main_menu start
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
#       Shows the NordVPN connection status in the system tray and runs nordlist.sh when clicked.
#       Mint-Menu - "Applets" - Download tab - "Bash-Sensors" - Install - Manage tab - (+)Add to panel
#       https://cinnamon-spices.linuxmint.com/applets/view/231
#
#       To use the NordVPN icons from https://github.com/ph202107/nordlist/tree/main/icons
#       Download the icons to your device and modify "PATH_TO_ICON" in the command below.
#       Green = Connected, Red = Disconnected
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
# NordVPN Indicator Cinnamon Applet - no status with Nord update or feature notice
#   ~/.local/share/cinnamon/applets/nordvpn-indicator@nickdurante/applet.js
#   Line 111 - Change [0] to [1]
#       let result = status.split("\n")[1].split(": ")[1];
#   Reload applet
#       dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'nordvpn-indicator@nickdurante' string:'APPLET'
#
