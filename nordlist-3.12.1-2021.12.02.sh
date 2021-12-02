#!/bin/bash
# Requires bash v4 or greater.
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added a
# lot of comments to help fellow newbies customize the script.
#
# It looks like this:
# https://i.imgur.com/5JFLTBb.png
# https://i.imgur.com/dKnK7u9.png
# https://i.imgur.com/To2BbUI.png
# https://i.imgur.com/077qYI3.png
#
# /u/pennyhoard20 on reddit
# https://github.com/ph202107/nordlist
#
# Last tested with NordVPN Version 3.12.1 on Linux Mint 20.2
# (Bash 5.0.17) December 2, 2021
#
# =====================================================================
# Instructions
# 1) Save as nordlist.sh
#       For convenience I use a directory in my PATH (echo $PATH)
#       eg. /home/username/bin/nordlist.sh
# 2) Make the script executable with
#       "chmod +x nordlist.sh"
# 3) For the customized menu ASCII, to generate ASCII headings, and to
#       use NordVPN API functions these small programs are required *
#       eg "sudo apt-get install figlet lolcat curl jq"
# 4) At the terminal type "nordlist.sh"
#
# =====================================================================
# * The script will work without figlet and lolcat after making
#   these modifications:
# 1) In "function logo"
#       - change "custom_ascii" to "std_ascii"
# 2) In "function heading"
#       - remove the hash mark (#) before "echo"
#       - remove the hash mark (#) before "return"
#
# =====================================================================
# Other small programs used:
# "highlight"       Settings-Script             (function fscriptinfo)
# "youtube-dl"      Settings-Tools-youtube-dl   (function ftools)
#
# For VPN On/Off status in the system tray, I use the Linux Mint
# Cinnamon applet "NordVPN Indicator".  Github may have similar apps.
#
# =====================================================================
# CUSTOMIZATION
# (all of these are optional)
#
# Specify your P2P preferred location.  eg p2pwhere="Canada"
p2pwhere=""
#
# Specify your Obfuscated_Servers preferred location.
# The location must support obfuscation.  eg obwhere="United_States"
obwhere=""
#
# Specify your Auto-Connect location.  eg acwhere="Toronto"
# When obfuscate is enabled, the location must support obfuscation.
acwhere=""
#
# Specify your Custom DNS servers with a description.
# Can specify up to 3 IP addresses separated by a space.
#default_dns="192.168.1.70"; dnsdesc="PiHole"
default_dns="103.86.96.100 103.86.99.100"; dnsdesc="Nord"
#
# Specify a VPN hostname/IP to use for testing while the VPN is off.
# Can still enter any hostname later, this is just a default choice.
default_host="ca1207.nordvpn.com"   # eg. "ca1207.nordvpn.com"
#
# Confirm the location of the NordVPN changelog on your system.
#nordchangelog="/var/lib/dpkg/info/nordvpn.changelog"
nordchangelog="/usr/share/doc/nordvpn/changelog.gz"
#
# Always 'Rate Server' when disconnecting via the main menu. "y" or "n"
alwaysrate="y"
#
# Show the logo when the script exits.  "y" or "n"
exitlogo="y"
#
# When exitlogo="y", also ping the connected server and query
# the server load.  Requires 'curl' and 'jq'.  "y" or "n"
exitping="n"
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
# Firewall, KillSwitch, CyberSec, Notify, AutoConnect, IPv6
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
# The Main Menu starts on line 2152.  Recommend configuring the
# first nine main menu items to suit your needs.
#
# Add your Whitelist configuration commands to "function fwhitelist".
# Configure "function set_defaults" to set up a default NordVPN config.
#
# Change the main menu figlet ASCII style in "function custom_ascii"
# Change the figlet ASCII style for headings in "function heading"
# Change the highlighted text and indicator colors under "COLORS"
#
# Note: "Restart" and "IPTables" require a sudo password
#   - see "function frestart"
#   - see 'function fiptables'
#
# ==End================================================================
#
# COLORS
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
# Change colors here if needed.
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
#
function std_ascii {
    # This ASCII can display above the main menu if you
    # prefer to use other ASCII art.
    # Place any ASCII art between cat << "EOF" and EOF
    # and specify std_ascii in "function logo".
    echo -e ${SColor}
    #
cat << "EOF"
 _   _               ___     ______  _   _
| \ | | ___  _ __ __| \ \   / /  _ \| \ | |
|  \| |/ _ \| '__/ _' |\ \ / /| |_) |  \| |
| |\  | (_) | | | (_| | \ V / |  __/| |\  |
|_| \_|\___/|_|  \__,_|  \_/  |_|   |_| \_|

EOF
    #
    echo -e ${Color_Off}
}
function custom_ascii {
    # This is the customized ASCII generated by figlet, displayed above the main menu.
    # Specify custom_ascii in "function logo".
    # Any text or variable can be used, single or multiple lines.
    if [[ "$connected" == "connected" ]]; then
        #figlet NordVPN                         # standard font in mono
        #figlet NordVPN | lolcat -p 0.8         # standard font colorized
        #figlet -f slant NordVPN | lolcat       # slant font, colorized
        #figlet $city | lolcat -p 1             # display the city name, more rainbow
        figlet -f slant $city | lolcat -p 1.7  # city in slant font
        #figlet $country | lolcat -p 1.5        # display the country
        #figlet $transferd | lolcat  -p 1       # display the download statistic
        #
    else
        figlet NordVPN                          # style when disconnected
    fi
}
function logo {
    set_vars
    if [[ "$1" != "tools" ]]; then
        #
        # Specify  std_ascii or custom_ascii on the line below.
        custom_ascii
        #
    fi
    echo -e $connectedcl: ${CIColor}$city ${COColor}$country ${SVColor}$server ${IPColor}$ip ${Color_Off}
    echo -e $techpro$fw$ks$cs$ob$no$ac$ip6$dns$fst
    echo -e $transferc ${UPColor}$uptime ${Color_Off}
    echo
    # all indicators: $techpro$fw$ks$cs$ob$no$ac$ip6$dns$fst
}
function heading {
    clear -x
    # This is the ASCII that displays after a menu selection is made.
    #
    # Uncomment the next two lines if figlet is not installed
    #echo ""; echo -e "${HColor}/// $1 ///${Color_Off}"; echo ""
    #return
    #
    # Display longer names with smaller font to prevent wrapping.
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
function fwhitelist {
    heading "Whitelist"
    echo "Edit the script to add your whitelist commands to"
    echo -e "${LColor} 'function fwhitelist' ${Color_Off}"
    echo
    echo "This option may be useful to restore a default whitelist"
    echo "after installing, using 'Reset', or making other changes."
    echo
    echo -e "${EColor}Current Settings:${Color_Off}"
    if nordvpn settings | grep -i -q "whitelist"; then
        nordvpn settings | grep -A100 -i "whitelist" --color=none
        echo
    else
        echo "No whitelist entries."
        echo
    fi
    echo -e "Enter ${WColor}X${Color_Off} to remove all entries."
    read -n 1 -r -p "Apply your default whitelist settings? (y/n/X) "
    echo
    echo
    if [[ $REPLY =~ ^[Xx]$ ]]; then
        nordvpn whitelist remove all
        echo
    elif [[ $REPLY =~ ^[Yy]$ ]]; then
        # Enter one command per line.  Example:
        #
        #nordvpn whitelist remove all    # Clear the Whitelist
        #nordvpn whitelist add subnet 192.168.1.0/24
        #
        echo
    else
        echo "No changes made."
        echo
    fi
    nordvpn settings | grep -A100 -i "whitelist" --color=none
    echo
    if [[ "$1" == "back" ]]; then return; fi
    main_menu
}
function set_defaults {
    # Calling this function can be useful to change multiple settings
    # at once and get back to a typical configuration.
    #
    # Configure as needed and comment-out or remove the next two lines.
    echo -e "${WColor}** 'function set_defaults' not configured **${Color_Off}"; echo ""
    return
    #
    # Notes:
    # - NordLynx is UDP only
    # - Obfuscate requires OpenVPN
    # - Kill Switch requires Firewall
    # - Cybersec disables CustomDNS and vice versa
    #
    # For each setting uncomment one of the two choices (or neither).
    #
    #if [[ "$technology" == "openvpn" ]]; then nordvpn set technology nordlynx; set_vars; fi
    if [[ "$technology" == "nordlynx" ]]; then nordvpn set technology openvpn; set_vars; fi
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
    #if [[ "$cybersec" == "disabled" ]]; then nordvpn set cybersec enabled; fi
    if [[ "$cybersec" == "enabled" ]]; then nordvpn set cybersec disabled; fi
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
    #if [[ "$dns_set" == "disabled" ]]; then nordvpn set dns $default_dns; fi
    if [[ "$dns_set" != "disabled" ]]; then nordvpn set dns disabled; fi
    #
    echo
    echo -e "${LColor}Default configuration applied.${Color_Off}"
    echo
}
#
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
    #
    # VARIABLES
    #
    # Store info in arrays (BASH v4)
    readarray -t nstat < <( nordvpn status | tr -d '\r' )
    readarray -t nsets < <( nordvpn settings | tr -d '\r' | tr '[:upper:]' '[:lower:]' )
    #
    # "nordvpn status" - array nstat - search function nstatbl
    # When disconnected, $connected is the only variable from nstat
    connected=$(nstatbl "Status" | cut -f2 -d':' | cut -c 2- | tr '[:upper:]' '[:lower:]')
    nordhost=$(nstatbl "Current server" | cut -f3 -d' ') # full hostname
    server=$(echo "$nordhost" | cut -f1 -d'.')           # shortened hostname
    # country and city names may have spaces eg. "United States"
    country=$(nstatbl "Country" | cut -f2 -d':' | cut -c 2-)
    city=$(nstatbl "City" | cut -f2 -d':' | cut -c 2-)
    ip=$(nstatbl "Server IP" | cut -f 2-3 -d' ')        # includes "IP: "
    ipaddr=$(echo "$ip" | cut -f2 -d' ')                # IP address only
    technology2=$(nstatbl "technology" | cut -f3 -d' ') # variable not used
    protocol2=$(nstatbl "protocol" | cut -f3 -d' ' | tr '[:lower:]' '[:upper:]')
    transferd=$(nstatbl "Transfer" | cut -f 2-3 -d' ')  # download stat with units
    transferu=$(nstatbl "Transfer" | cut -f 5-6 -d' ')  # upload stat with units
    transfer="\u25bc $transferd  \u25b2 $transferu"     # unicode up/down arrows
    uptime=$(nstatbl "Uptime" | cut -f 1-5 -d' ')
    #
    # "nordvpn settings" - array nsets (all elements lowercase) - search function nsetsbl
    # $protocol and $obfuscate are not listed when using NordLynx
    technology=$(nsetsbl "Technology" | cut -f2 -d':' | cut -c 2-)
    protocol=$(nsetsbl "Protocol" | cut -f2 -d' ' | tr '[:lower:]' '[:upper:]')
    firewall=$(nsetsbl "Firewall" | cut -f2 -d' ')
    killswitch=$(nsetsbl "Kill" | cut -f3 -d' ')
    cybersec=$(nsetsbl "CyberSec" | cut -f2 -d' ')
    obfuscate=$(nsetsbl "Obfuscate" | cut -f2 -d' ')
    notify=$(nsetsbl "Notify" | cut -f2 -d' ')
    autocon=$(nsetsbl "Auto" | cut -f2 -d' ')
    ipversion6=$(nsetsbl "IPv6" | cut -f2 -d' ')
    dns_set=$(nsetsbl "DNS" | cut -f2 -d' ')                # disabled or not=disabled
    dns_srvrs=$(nsetsbl "DNS" | tr '[:lower:]' '[:upper:]') # Server IPs, includes "DNS: "
    #
    # Prefer common spelling.
    if [[ "$technology" == "openvpn" ]]; then technologyd="OpenVPN"; fi
    if [[ "$technology" == "nordlynx" ]]; then technologyd="NordLynx"; fi
    #
    # To display the protocol for either Technology whether connected or disconnected.
    if [[ "$connected" == "connected" ]]; then
        protocold=$protocol2
    elif [[ "$technology" == "nordlynx" ]]; then
        protocold="UDP"
    else
        protocold=$protocol
    fi
    #
    if [[ "$connected" == "connected" ]]; then
        connectedcl="${CNColor}${connected^}${Color_Off}"
        connectedc="${CNColor}$connected${Color_Off}"
    else
        connectedcl="${DNColor}${connected^}${Color_Off}"
        connectedc="${DNColor}$connected${Color_Off}"
    fi
    #
    transferc="${DLColor}\u25bc $transferd ${ULColor}\u25b2 $transferu${Color_Off}"
    #
    techpro=(${TIColor}"[$technologyd $protocold]"${Color_Off})
    #
    if [[ "$firewall" == "enabled" ]]; then
        fw=(${EIColor}[FW]${Color_Off})
        firewallc=(${EColor}"$firewall"${Color_Off})
    else
        fw=(${DIColor}[FW]${Color_Off})
        firewallc=(${DColor}"$firewall"${Color_Off})
    fi
    #
    if [[ "$killswitch" == "enabled" ]]; then
        ks=(${EIColor}[KS]${Color_Off})
        killswitchc=(${EColor}"$killswitch"${Color_Off})
    else
        ks=(${DIColor}[KS]${Color_Off})
        killswitchc=(${DColor}"$killswitch"${Color_Off})
    fi
    #
    if [[ "$cybersec" == "enabled" ]]; then
        cs=(${EIColor}[CS]${Color_Off})
    else
        cs=(${DIColor}[CS]${Color_Off})
    fi
    #
    if [[ "$obfuscate" == "enabled" ]]; then
        ob=(${EIColor}[OB]${Color_Off})
        obfuscatec=(${EColor}"$obfuscate"${Color_Off})
        obprompt=$(echo -e "${DColor}Disable${Color_Off} Obfuscate? (y/n) ")
    else
        ob=(${DIColor}[OB]${Color_Off})
        obfuscatec=(${DColor}"$obfuscate"${Color_Off})
        obprompt=$(echo -e "${EColor}Enable${Color_Off} Obfuscate? (y/n) ")
    fi
    #
    if [[ "$notify" == "enabled" ]]; then
        no=(${EIColor}[NO]${Color_Off})
    else
        no=(${DIColor}[NO]${Color_Off})
    fi
    #
    if [[ "$autocon" == "enabled" ]]; then
        ac=(${EIColor}[AC]${Color_Off})
    else
        ac=(${DIColor}[AC]${Color_Off})
    fi
    #
    if [[ "$ipversion6" == "enabled" ]]; then
        ip6=(${EIColor}[IP6]${Color_Off})
    else
        ip6=(${DIColor}[IP6]${Color_Off})
    fi
    #
    if [[ "$dns_set" == "disabled" ]]; then # reversed
        dns=(${DIColor}[DNS]${Color_Off})
    else
        dns=(${EIColor}[DNS]${Color_Off})
    fi
    #
    if [[ ${allfast[@]} =~ [Yy] ]]; then
        fst=(${FIColor}[F]${Color_Off})
    else
        fst=""
    fi
}
function discon {
    heading "$opt"
    echo
    echo "Option $REPLY - Connect to $opt"
    echo
    set_vars
    if [[ "$connected" == "connected" ]]; then
        echo -e "${WColor}** Disconnect **${Color_Off}"
        echo
        nordvpn disconnect; wait
        echo
        echo "Connect to $opt"
        echo
    fi
}
function discon2 {
    set_vars
    echo
    if [[ "$connected" == "connected" ]]; then
        echo -e "${WColor}** Disconnect **${Color_Off}"
        echo
        nordvpn disconnect; wait
        echo
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
        if [[ "$connected" == "connected" ]] && [[ "$exitping" =~ ^[Yy]$ ]]; then
            sleep 1  # on rare occasions ping doesn't work if sent too soon
            if [[ "$nordhost" == *"onion"* ]]; then
                ping -c 3 -q $ipaddr
            else
                ping -c 3 -q $nordhost
            fi
            echo
            server_load
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
function fcountries {
    # submenu for all available countries and cities
    heading "Countries"
    countrylist=($(nordvpn countries | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | tail -n +"$numtail" | sort))
    # Replaced "Bosnia_And_Herzegovina" with "Sarajevo" to help compact the list.
    countrylist=("${countrylist[@]/Bosnia_And_Herzegovina/Sarajevo}")
    countrylist+=( "Exit" )
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
        fi
        if (( 1 <= $REPLY )) && (( $REPLY <= $numcountries )); then
            #
            cities
            #
        else
            echo
            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
            echo
            echo "Select any number from 1-$numcountries ($numcountries to Exit)."
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
    citylist=($(nordvpn cities $xcountry | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | tail -n +"$numtail" | sort))
    citylist+=( "Default" )
    citylist+=( "Exit" )
    numcities=${#citylist[@]}
    if [[ "$numcities" == "3" ]] && [[ "$fast7" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast7 is enabled.${Color_Off}"
        echo
        echo "Only one available city in $xcountry."
        echo
        echo -e "Connecting to ${LColor}${citylist[0]}${Color_Off}."
        echo
        discon2
        nordvpn connect $xcountry
        status
        exit
    fi
    PS3=$'\n''Connect to City: '
    select xcity in "${citylist[@]}"
    do
        if [[ "$xcity" == "Exit" ]]; then
            main_menu
        fi
        if [[ "$xcity" == "Default" ]]; then
            echo
            echo "Connecting to the best available city."
            echo
            discon2
            nordvpn connect $xcountry
            status
            exit
        fi
        if (( 1 <= $REPLY )) && (( $REPLY <= $numcities )); then
            heading "$xcity"
            echo
            discon2
            echo "Connecting to $xcity, $xcountry."
            echo
            nordvpn connect $xcity
            status
            exit
        else
            echo
            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
            echo
            echo "Select any number from 1-$numcities ($numcities to Exit)."
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
    echo
    if [[ "$specsrvr" == "" ]]; then return; fi
    if [[ "$specsrvr" == *"nord"* ]]; then specsrvr=$( echo "$specsrvr" | cut -f1 -d'.' ); fi
    if [[ "$specsrvr" == *"socks"* ]]; then echo -e "${WColor}Unable to connect to SOCKS servers${Color_Off}"; echo; return; fi
    if [[ "$specsrvr" == *"-"* ]] && [[ "$specsrvr" != *"onion"* ]] && [[ "$technology" == "nordlynx" ]]; then
        echo -e "${WColor}Double-VPN Servers require OpenVPN${Color_Off}"; echo; return
    fi
    read -n 1 -r -p "Apply your default config? (y/n) " specdef
    echo
    discon2
    if [[ $specdef =~ ^[Yy]$ ]]; then set_defaults; fi
    echo "Connect to $specsrvr"
    echo
    nordvpn connect $specsrvr
    status
    if [[ ! "$exitlogo" =~ ^[Yy]$ ]]; then set_vars; fi
    # test commands
    # app commands
}
function fallgroups {
    # all available groups
    heading "All Groups"
    grouplist=($(nordvpn groups | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | tail -n +"$numtail" | sort))
    grouplist+=( "Exit" )
    numgroups=${#grouplist[@]}
    echo "Groups that are available with"
    echo
    echo -e "Technology: ${TColor}$technologyd${Color_Off}"
    if [[ "$technology" == "openvpn" ]]; then
        echo -e "Obfuscate: $obfuscatec"
    fi
    echo
    PS3=$'\n''Connect to Group: '
    select xgroup in "${grouplist[@]}"
    do
        if [[ "$xgroup" == "Exit" ]]; then
            main_menu
        fi
        if (( 1 <= $REPLY )) && (( $REPLY <= $numgroups )); then
            heading "$xgroup"
            echo
            discon2
            echo "Connecting to $xgroup."
            echo
            nordvpn connect $xgroup
            status
            exit
        else
            echo
            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
            echo
            echo "Select any number from 1-$numgroups ($numgroups to Exit)."
        fi
    done
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
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Set Technology to OpenVPN."
    echo "Specify the Protocol."
    echo "Set Obfuscate to enabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Obfuscated_Servers group $obwhere"
    echo -e ${Color_Off}
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
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
    # Not available with NordLynx
    # Not available with obfuscate enabled
    heading "Double-VPN"
    echo "Double VPN is a privacy solution that sends your internet"
    echo "traffic through two VPN servers, encrypting it twice."
    echo
    echo -e "Current settings: $techpro$fw$ks$ob"
    echo
    echo "To connect to the Double_VPN group the"
    echo "following changes will be made (if necessary):"
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Set Technology to OpenVPN."
    echo "Specify the Protocol."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Double_VPN group."
    echo -e ${Color_Off}
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "nordlynx" ]]; then
            nordvpn set technology openvpn; wait
            echo
            # ask_protocol will update $protocol and $obfuscate
        fi
        ask_protocol
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
            echo
        fi
        killswitch_groups
        echo "Connect to the Double_VPN group."
        echo
        nordvpn connect Double_VPN
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
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Specify the Protocol (for OpenVPN)."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Onion_Over_VPN group."
    echo -e ${Color_Off}
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "openvpn" ]]; then
            ask_protocol
        fi
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
            echo
        fi
        killswitch_groups
        echo "Connect to the Onion_Over_VPN group."
        echo
        nordvpn connect Onion_Over_VPN
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
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Change the Protocol to UDP (choice)."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the P2P group $p2pwhere"
    echo -e ${Color_Off}
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 is enabled.  Automatically connect.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$protocol" == "TCP" ]]; then
            ask_protocol
        fi
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
    echo " use Obfuscated or Double-VPN servers and to use TCP."
    echo "NordLynx is built around the WireGuard VPN protocol"
    echo " and may be faster with less overhead."
    echo
    echo -e "Currently using ${TColor}$technologyd${Color_Off}."
    echo
    if [[ "$fast3" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast3 is enabled.  Changing the Technology.${Color_Off}"
        REPLY="y"
    elif [[ "$technology" == "openvpn" ]]; then
        read -n 1 -r -p "Change the Technology to NordLynx? (y/n) "
    else
        read -n 1 -r -p "Change the Technology to OpenVPN? (y/n) "
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
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
        echo -e "Continue to use ${TColor}$technologyd${Color_Off}."
        echo
    fi
    if [[ "$1" == "obback" ]]; then
        set_vars
        fobfuscate
    fi
    main_menu
}
function fprotocol {
    heading "Protocol"
    if [[ "$technology" == "nordlynx" ]]; then
        echo
        echo -e "Technology is currently set to ${TColor}$technologyd${Color_Off}."
        echo
        echo "No protocol to specify when using NordLynx,"
        echo "WireGuard supports UDP only."
        echo
        echo "Change Technology to OpenVPN to use TCP or UDP."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting? (y/n) "
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
        echo -e "The Protocol is set to ${TColor}$protocol${Color_Off}."
        echo
        if [[ "$fast3" =~ ^[Yy]$ ]]; then
            echo -e "${FColor}[F]ast3 is enabled.  Changing the Protocol.${Color_Off}"
            REPLY="y"
        elif [[ "$protocol" == "UDP" ]]; then
            read -n 1 -r -p "Change the Protocol to TCP? (y/n) "
        else
            read -n 1 -r -p "Change the Protocol to UDP? (y/n) "
        fi
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            discon2
            if [[ "$protocol" == "UDP" ]]; then
                nordvpn set protocol TCP; wait
            else
                nordvpn set protocol UDP; wait
            fi
            echo
        else
            echo
            echo -e "Continue to use ${TColor}$protocol${Color_Off}."
            echo
        fi
    fi
    main_menu
}
function ask_protocol {
    # Ask to choose TCP/UDP if changing to OpenVPN, using Obfuscate,
    # and when connecting to Obfuscated or Double-VPN Servers
    #
    # set $protocol if technology just changed from NordLynx
    set_vars
    echo -e "The Protocol is set to ${TColor}$protocol${Color_Off}."
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
        read -n 1 -r -p "Change the Protocol to TCP? (y/n) "
    else
        read -n 1 -r -p "Change the Protocol to UDP? (y/n) "
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$protocol" == "UDP" ]]; then
            nordvpn set protocol TCP; wait
        else
            nordvpn set protocol UDP; wait
        fi
        echo
    else
        echo
        echo -e "Continue to use ${TColor}$protocol${Color_Off}."
        echo
    fi
}
function change_setting {
    # $1 = Nord command
    # $2 = override fast2 and main_menu
    #
    if [[ "$1" == "firewall" ]]; then chgname="the Firewall"; chgvar="$firewall"; chgind="$fw"; chgloc=""; fi
    if [[ "$1" == "killswitch" ]]; then chgname="the Kill Switch"; chgvar="$killswitch"; chgind="$ks"; chgloc=""; fi
    if [[ "$1" == "cybersec" ]]; then chgname="CyberSec"; chgvar="$cybersec"; chgind="$cs"; chgloc=""; fi
    if [[ "$1" == "notify" ]]; then chgname="Notify"; chgvar="$notify"; chgind="$no"; chgloc=""; fi
    if [[ "$1" == "autoconnect" ]]; then chgname="Auto-Connect"; chgvar="$autocon"; chgind="$ac"; chgloc="$acwhere"; fi
    if [[ "$1" == "ipv6" ]]; then chgname="IPv6"; chgvar="$ipversion6"; chgind="$ip6"; chgloc=""; fi
    #
    if [[ "$chgvar" == "enabled" ]]; then
        chgvarc=(${EColor}"$chgvar"${Color_Off})
        chgprompt=$(echo -e "${DColor}Disable${Color_Off} $chgname? (y/n) ")
    else
        chgvarc=(${DColor}"$chgvar"${Color_Off})
        chgprompt=$(echo -e "${EColor}Enable${Color_Off} $chgname? (y/n) ")
    fi
    echo -e "$chgind $chgname is $chgvarc."
    echo
    if [[ "$fast2" =~ ^[Yy]$ ]] && [[ "$2" != "override" ]]; then   # option: remove second condition
        echo -e "${FColor}[F]ast2 is enabled.  Changing the setting.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "$chgprompt"
        echo
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$chgvar" == "disabled" ]]; then
            if [[ "$1" == "cybersec" ]] && [[ "$dns_set" != "disabled" ]]; then
                nordvpn set dns disabled; wait
                echo
            fi
            if [[ "$1" == "autoconnect" ]]; then
                echo -e "Enable $chgname ${LColor}$chgloc${Color_Off}"
                echo
            fi
            if [[ "$1" == "killswitch" ]] && [[ "$firewall" == "disabled" ]]; then
                # when connecting to Groups or changing the setting from IPTables
                echo -e "${WColor}Enabling the Firewall.${Color_Off}"
                echo
                nordvpn set firewall enabled; wait
                echo
            fi
            nordvpn set $1 enabled $chgloc; wait
            echo
        else
            if [[ "$1" == "firewall" ]] && [[ "$killswitch" == "enabled" ]]; then
                # when changing the setting from IPTables
                echo -e "${WColor}Disabling the Kill Switch.${Color_Off}"
                echo
                nordvpn set killswitch disabled; wait
                echo
            fi
            nordvpn set $1 disabled; wait
            echo
        fi
    else
        echo -e "$chgind Keep $chgname $chgvarc."
        echo
    fi
    if [[ "$2" == "override" ]]; then return; fi
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
function fcybersec {
    heading "CyberSec"
    echo
    echo "CyberSec is a feature protecting you from ads,"
    echo "unsafe connections, and malicious sites."
    echo
    echo -e "Enabling CyberSec disables Custom DNS $dns"
    if [[ "$dns_set" != "disabled" ]]; then
        echo "Current $dns_srvrs"
    fi
    echo
    change_setting "cybersec"
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
        echo -e "$ob When obfuscate is enabled, the Auto-Connect location"
        echo "     must support obfuscation."
        echo
    fi
    if [[ "$autocon" == "disabled" ]] && [[ "$acwhere" != "" ]]; then
        echo -e "Auto-Connect location: ${LColor}$acwhere${Color_Off}"
        echo
    fi
    change_setting "autoconnect"
}
function fipversion6 {
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
        echo -e "Technology is currently set to ${TColor}$technologyd${Color_Off}."
        echo
        echo "Obfuscation is not available when using NordLynx."
        echo "Change Technology to OpenVPN to use Obfuscation."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting and return? (y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ftechnology "obback"
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
        if [[ "$fast3" =~ ^[Yy]$ ]]; then
            echo -e "${FColor}[F]ast3 is enabled.  Changing the setting.${Color_Off}"
            REPLY="y"
        else
            read -n 1 -r -p "$obprompt"
        fi
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            discon2
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
            echo
        fi
    fi
    main_menu
}
function nordsetdns {
    echo
    set_vars
    if [[ "$cybersec" == "enabled" ]]; then
        nordvpn set cybersec disabled; wait
        echo
    fi
    nordvpn set dns $1 $2 $3; wait
    echo
}
function fcustomdns {
    heading "CustomDNS"
    echo "The NordVPN app automatically uses NordVPN DNS servers"
    echo "to prevent DNS leaks. (103.86.96.100 and 103.86.99.100)"
    echo "You can specify your own Custom DNS servers instead."
    echo
    echo -e "Enabling Custom DNS disables CyberSec $cs"
    echo
    if [[ "$dns_set" == "disabled" ]]; then
        echo -e "$dns Custom DNS is ${DColor}disabled${Color_Off}."
    else
        echo -e "$dns Custom DNS is ${EColor}enabled${Color_Off}."
        echo "Current $dns_srvrs"
    fi
    echo
    PS3=$'\n''Choose an Option: '
    submcdns=("Nord (103.86.96.100, 103.86.99.100)" "AdGuard (94.140.14.14 94.140.15.15)" "Quad9 (9.9.9.9, 149.112.112.11)" "Cloudflare (1.1.1.1, 1.0.0.1)" "Google (8.8.8.8, 8.8.4.4)" "Specify or Default" "Disable Custom DNS" "Exit")
    numsubmcnds=${#submcdns[@]}
    select cdns in "${submcdns[@]}"
    do
        case $cdns in
            "Nord (103.86.96.100, 103.86.99.100)")
                nordsetdns "103.86.96.100" "103.86.99.100"
                ;;
            "AdGuard (94.140.14.14 94.140.15.15)")
                nordsetdns "94.140.14.14" "94.140.15.15"
                ;;
            "Quad9 (9.9.9.9, 149.112.112.11)")
                nordsetdns "9.9.9.9" "149.112.112.11"
                ;;
            "Cloudflare (1.1.1.1, 1.0.0.1)")
                nordsetdns "1.1.1.1" "1.0.0.1"
                ;;
            "Google (8.8.8.8, 8.8.4.4)")
                nordsetdns "8.8.8.8" "8.8.4.4"
                ;;
            "Specify or Default")
                echo
                echo "Enter the DNS server IPs or hit 'Enter' for default."
                echo -e "Default: ${LColor}$dnsdesc ($default_dns)${Color_Off}"
                echo
                read -r -p "Up to 3 DNS server IPs: " dns3srvrs
                dns3srvrs=${dns3srvrs:-$default_dns}
                nordsetdns $dns3srvrs
                ;;
            "Disable Custom DNS")
                echo
                nordvpn set dns disabled; wait
                echo
                ;;
            "Exit")
                main_menu
                ;;
            *)
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numsubmcnds ($numsubmcnds to Exit)."
                ;;
        esac
    done
}
function faccount {
    heading "Account"
    echo
    PS3=$'\n''Choose an Option: '
    submacct=("Login" "Logout" "Browser Login" "Account Info" "Register" "Nord Version" "Changelog" "Nord Manual" "Support" "Exit")
    numsubmacct=${#submacct[@]}
    select acc in "${submacct[@]}"
    do
        case $acc in
            "Login")
                echo
                nordvpn login
                echo
                ;;
            "Logout")
                discon2
                nordvpn logout
                echo
                ;;
            "Browser Login")
                echo
                echo "From 'man nordvpn' Note 2:"
                echo "OAuth2 login without graphical user interface."
                echo "After finishing login in the browser, copy the link pointed by xdg-open button."
                echo "The following command can be invoked manually to finish the login process."
                echo "$ nordvpn login --callback <link>"
                echo
                nordvpn login --nordaccount
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
                echo "* untested"
                echo
                read -n 1 -r -p "Proceed? (y/n) "
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    discon2
                    nordvpn register
                fi
                ;;
            "Nord Version")
                echo
                nordvpn --version
                ;;
            "Changelog")
                echo
                #zless +G "$nordchangelog"
                #zcat "$nordchangelog"
                # version numbers are not in order (latest release != last entry)
                zless -p$( nordvpn --version | cut -f3 -d' ' ) "$nordchangelog"
                #
                nordrl="https://nordvpn.com/blog/nordvpn-linux-release-notes/"
                read -n 1 -r -p "$(echo -e "Open ${EColor}$nordrl${Color_Off} ? (y/n) ")"
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    xdg-open "$nordrl"
                fi
                ;;
            "Nord Manual")
                echo
                man nordvpn
                ;;
            "Support")
                echo
                echo "email: support@nordvpn.com"
                echo "https://support.nordvpn.com/"
                echo "https://nordvpn.com/contact-us/"
                echo
                ;;
            "Exit")
                main_menu
                ;;
            *)
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numsubmacct ($numsubmacct to Exit)."
                ;;
        esac
    done
}
function frestart {
    heading "Restart"
    echo
    echo "Restart nordvpn services."
    echo -e ${WColor}
    echo "Send commands:"
    echo "nordvpn set killswitch disabled (choice)"
    echo "nordvpn set autoconnect disabled (choice)"
    echo "sudo systemctl restart nordvpnd.service"
    echo "sudo systemctl restart nordvpn.service"
    echo -e ${Color_Off}
    echo
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$killswitch" == "enabled" ]]; then
            change_setting "killswitch" "override"
        fi
        if [[ "$autocon" == "enabled" ]]; then
            change_setting "autoconnect" "override"
        fi
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
            nordvpn login; wait
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
    echo -e ${WColor}
    echo "Send commands:"
    echo "nordvpn set killswitch disabled"
    echo "nordvpn disconnect"
    echo "nordvpn logout"
    echo "nordvpn whitelist remove all"
    echo "nordvpn set defaults"
    echo "Restart nordvpn services"
    echo "Apply your default configuration"
    echo -e ${Color_Off}
    echo
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # first four redundant
        if [[ "$killswitch" == "enabled" ]]; then
            nordvpn set killswitch disabled; wait
        fi
        discon2
        nordvpn logout; wait
        echo
        nordvpn whitelist remove all; wait
        echo
        nordvpn set defaults; wait
        echo
        echo -e "${LColor}Can also delete:${Color_Off}"
        echo "  /home/username/.config/nordvpn/nordvpn.conf"
        echo "  /var/lib/nordvpn/data/settings.dat"
        echo
        echo -e "${WColor}** Reminder **${Color_Off}"
        echo -e "${LColor}Reconfigure the Whitelist and other settings.${Color_Off}"
        echo
        read -n 1 -s -r -p "Press any key to restart services..."
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
    nordvpn settings | grep -A100 -i "whitelist" --color=none
    echo
    echo -e ${LColor}"sudo iptables -S"${Color_Off}
    sudo iptables -S
    echo
}
function fiptables {
    #https://old.reddit.com/r/nordvpn/comments/qgakq9/linux_killswitch_problems_iptables/
    # Only tested with Linux Mint
    heading "IPTables"
    echo "Flushing the IPTables may help resolve problems enabling or"
    echo "disabling the KillSwitch or with other connection issues."
    echo -e ${WColor}
    echo "** WARNING **"
    echo "  - This will CLEAR all of your Firewall rules"
    echo "  - Review 'function fiptables' before use"
    echo "  - Commands require 'sudo'"
    echo -e ${Color_Off}
    PS3=$'\n''Choose an option: '
    submipt=("View IPTables" "Firewall" "KillSwitch" "Whitelist" "Flush IPTables" "Restart Services" "ping google.com" "Examples" "Exit")
    numsubmipt=${#submipt[@]}
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
            "Whitelist")
                echo
                fwhitelist "back"
                fiptables_status
                ;;
            "Flush IPTables")
                echo
                echo -e ${WColor}"Flush the IPTables and clear all of your Firewall rules."${Color_Off}
                echo
                read -n 1 -r -p "Proceed? (y/n) "
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo
                    echo -e ${LColor}"IPTables Before:"${Color_Off}
                    sudo iptables -S
                    echo
                    echo -e ${WColor}"Flushing the IPTables"${Color_Off}
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
                    echo -e ${LColor}"IPTables After:"${Color_Off}
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
                echo -e ${WColor}"Disconnect the VPN and restart nordvpn services."${Color_Off}
                echo
                read -n 1 -r -p "Proceed? (y/n) "
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [[ "$autocon" == "enabled" ]]; then
                        change_setting "autoconnect" "override"
                    fi
                    discon2
                    echo -e ${LColor}"Restart NordVPN services. Wait 10s"${Color_Off}
                    echo
                    sudo systemctl restart nordvpnd.service
                    sudo systemctl restart nordvpn.service
                    for t in {10..1}; do
                        echo -n "$t "; sleep 1
                    done
                    echo
                    fiptables_status
                    echo -e ${LColor}"ping -c 3 google.com"${Color_Off}
                    ping -c 3 google.com
                    echo
                else
                    echo
                    echo "No changes made."
                    echo
                fi
                ;;
            "ping google.com")
                fiptables_status
                echo -e ${LColor}"ping -c 3 google.com"${Color_Off}
                ping -c 3 google.com
                echo
                ;;
            "Examples")
                echo
                echo -e "${EColor}Examples${Color_Off}"
                echo
                echo -e "${LColor}KillSwitch Active - Interface eno1${Color_Off}"
                echo "  -A INPUT -i eno1 -j DROP"
                echo "  -A OUTPUT -o eno1 -j DROP"
                echo
                echo -e "${LColor}Whitelist Active - Subnet 192.168.1.0/24${Color_Off}"
                echo "  -A INPUT -s 192.168.1.0/24 -i eno1 -j ACCEPT"
                echo "  -A OUTPUT -d 192.168.1.0/24 -o eno1 -j ACCEPT"
                echo
                echo -e "${LColor}VPN Connected - Server IP: 66.115.146.233${Color_Off}"
                echo "  -A INPUT -s 66.115.146.233/32 -i eno1 -j ACCEPT"
                echo "  -A OUTPUT -d 66.115.146.233/32 -o eno1 -j ACCEPT"
                echo
                ;;
            "Exit")
                sudo -K     # timeout sudo
                main_menu
                ;;
            *)
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numsubmipt ($numsubmipt to Exit)."
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
        read -n 1 -r -p "$(echo -e Rating 1-5 [e${LColor}x${Color_Off}it]): " rating
        echo
        if [[ $rating =~ ^[Xx]$ ]] || [[ $rating == "" ]]; then
            break
        fi
        if (( 1 <= $rating )) && (( $rating <= 5 )); then
            echo
            nordvpn rate $rating
            echo
            break
        else
            echo
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
    echo "Checking the server load..."
    echo
    sload=$(timeout 10 curl --silent https://api.nordvpn.com/server/stats/$nordhost | jq .percent)
    if [[ $sload == "" ]]; then
        echo "Request timed out."
    elif (( $sload <= 30 )); then
        echo -e "$nordhost load = ${EIColor}$sload%${Color_Off}"
    elif (( $sload <= 60 )); then
        echo -e "$nordhost load = ${FIColor}$sload%${Color_Off}"
    else
        echo -e "$nordhost load = ${DIColor}$sload%${Color_Off}"
    fi
    echo
}
function allvpnservers {
    heading "All Servers"
    if (( ${#allnordservers[@]} == 0 )); then
        echo "Retrieving the list of NordVPN servers..."
        echo "  (To use a text file see 'function allvpnservers')"
        readarray -t allnordservers < <( curl --silent https://api.nordvpn.com/server | jq --raw-output '.[].domain' | sort --version-sort )
        #
        # Use a text file instead:
        #readarray -t allnordservers < <( cat ~/allnordservers.txt ); echo -e "${LColor}(Using text file)${Color_Off}"
    fi
    echo "Count: ${#allnordservers[@]}"
    echo
    PS3=$'\n''Choose an option: '
    submallvpn=("List All Servers" "Double-VPN Servers" "Onion Servers" "SOCKS Servers" "Search" "Connect" "Exit")
    numsubmallvpn=${#submallvpn[@]}
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
                echo "Double-VPN Servers: $( printf '%s\n' "${allnordservers[@]}" | grep "-" | grep -i -v -e "socks" -e "onion" | wc -l )"
                echo
                ;;
            "Onion Servers")
                echo
                echo -e "${LColor}Onion Servers${Color_Off}"
                echo
                printf '%s\n' "${allnordservers[@]}" | grep -i "onion"
                echo
                echo "Onion Servers: $( printf '%s\n' "${allnordservers[@]}" | grep -i "onion" | wc -l )"
                echo
                ;;
            "SOCKS Servers")
                echo
                echo -e "${LColor}SOCKS Servers${Color_Off}"
                echo
                printf '%s\n' "${allnordservers[@]}" | grep -i "socks"
                echo
                echo "SOCKS Servers: $( printf '%s\n' "${allnordservers[@]}" | grep -i "socks" | wc -l )"
                echo
                echo "Proxy names and locations available here:"
                echo -e "${EColor}https://support.nordvpn.com/Connectivity/Proxy/1047410732/Proxy-setup-on-uTorrent.htm${Color_Off}"
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
                echo "'$allvpnsearch' Count: $( printf '%s\n' "${allnordservers[@]}" | grep -i "$allvpnsearch" | wc -l )"
                echo
                ;;
            "Connect")
                fhostname
                ;;
            "Exit")
                nordapi
                ;;
            *)
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numsubmallvpn ($numsubmallvpn to Exit)."
                ;;
        esac
    done
}
function nordapi {
    heading "NordVPN API"
    echo
    echo "Some commands copied from"
    echo -e "${EColor}https://sleeplessbeastie.eu/2019/02/18/how-to-use-public-nordvpn-api/${Color_Off}"
    echo "Requires 'curl' and 'jq'"
    echo "Commands may take a few seconds to complete."
    echo
    if [[ "$connected" == "connected" ]]; then
        echo -e "Connected to ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    PS3=$'\n''API Call: '
    submapi=("Host Server Load" "Host Server Info" "Top 15 Recommended" "Top 15 By Country" "#Servers per Country" "All VPN Servers" "Change Host" "Connect" "Exit")
    numsubmapi=${#submapi[@]}
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
                curl --silent https://api.nordvpn.com/server | jq '.[] | select(.domain == "'$nordhost'")'
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
                read -r -p "Country Code: " ccode
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
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numsubmapi ($numsubmapi to Exit)."
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
function ftools {
    heading "Tools"
    if [[ "$connected" == "connected" ]]; then
        logo "tools"
        PS3=$'\n''Choose an option: '
    else
        echo -e "${WColor}** VPN is Disconnected **${Color_Off}"
        echo
        read -r -p "Enter a Hostname/IP [Default $default_host]: " nordhost
        nordhost=${nordhost:-$default_host}
        echo
        echo -e "Hostname: ${LColor}$nordhost${Color_Off}"
        echo "(Does not affect 'Rate VPN Server')"
        echo
        PS3=$'\n''Choose an option (VPN Off): '
    fi
    nettools=("NordVPN API" "Rate VPN Server" "www.speedtest.net" "youtube-dl" "ping vpn" "ping google" "my traceroute" "ipleak.net" "dnsleaktest.com" "world map" "Change Host" "Exit")
    numnettools=${#nettools[@]}
    select tool in "${nettools[@]}"
    do
        case $tool in
            "NordVPN API")
                nordapi
                ;;
            "Rate VPN Server")
                rate_server
                ;;
            "www.speedtest.net")
                xdg-open http://www.speedtest.net/  # default browser
                #/usr/bin/firefox --new-window http://www.speedtest.net/
                #/usr/bin/firefox --new-window https://speedof.me/
                #/usr/bin/firefox --new-window https://fast.com
                #/usr/bin/firefox --new-window https://www.linode.com/speed-test/
                #/usr/bin/firefox --new-window http://speedtest-blr1.digitalocean.com/
                ;;
            "youtube-dl")
                # test speed by downloading a youtube video to /dev/null
                # this video is about 60MB, can use any video
                echo
                youtube-dl -f best --no-part --no-cache-dir -o /dev/null --newline https://www.youtube.com/watch?v=bkZac30P5DM
                echo
                ;;
            "ping vpn")
                echo
                echo -e "${LColor}ping -c 5 $nordhost${Color_Off}"
                echo
                ping -c 5 $nordhost
                echo
                ;;
            "ping google")
                clear -x
                echo -e ${LColor}
                echo "Ping Google DNS 8.8.8.8, 8.8.4.4"
                echo "Ping Cloudflare DNS 1.1.1.1, 1.0.0.1"
                echo "Ping Telstra Australia 139.130.4.5"
                echo -e ${FColor}
                echo "(CTRL-C to quit)"
                echo -e ${Color_Off}
                echo -e "${LColor}===== Google =====${Color_Off}"
                ping -c 5 8.8.8.8
                echo
                ping -c 5 8.8.4.4
                echo
                echo -e "${LColor}===== Cloudflare =====${Color_Off}"
                ping -c 5 1.1.1.1
                echo
                ping -c 5 1.0.0.1
                echo
                echo -e "${LColor}===== Telstra =====${Color_Off}"
                ping -c 5 139.130.4.5
                echo
                ;;
            "my traceroute")
                mtr $nordhost
                ;;
            "ipleak.net")
                xdg-open https://ipleak.net/
                ;;
            "dnsleaktest.com")
                xdg-open https://dnsleaktest.com
                ;;
            "world map")
                # may be possible to highlight location
                echo
                echo -e "${LColor}OpenStreetMap ASCII World Map${Color_Off}"
                echo "- arrow keys to navigate"
                echo "- 'a' and 'z' to zoom"
                echo "- 'q' to quit"
                echo
                read -n 1 -r -p "telnet mapscii.me? (y/n) "
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
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numnettools ($numnettools to Exit)."
                ;;
        esac
    done
}
function fdefaults {
    defaultsc=(${LColor}"[Defaults]"${Color_Off}'\n')
    echo
    echo -e "$defaultsc  Disconnect and apply the NordVPN settings"
    echo "  specified in 'function set_defaults'."
    echo
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        set_defaults
        echo
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
    numlines=$(( $endline - $startline + 2 ))
    #cat -n "$0" | head -n $endline | tail -n $numlines
    highlight -l -O xterm256 "$0" | head -n $endline | tail -n $numlines
    echo
    echo "Need to edit the script to change these settings."
    echo
    read -n 1 -r -p "Open $0 with the default editor? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    # https://unix.stackexchange.com/questions/3886/difference-between-nohup-disown-and
    # command > /dev/null 2>&1 &
        xdg-open "$0"
        exit
    fi
}
function fquickconnect {
    # This is an alternate method of connecting to the NordVPN recommended server.
    # In some cases it may be faster than using "nordvpn connect"
    # Will disconnect (if KillSwitch is disabled) to find the nearest best server.
    # Requires 'curl' and 'jq'
    # Auguss82 via github
    heading "QuickConnect"
    if [[ "$killswitch" == "disabled" ]]; then
        discon2
    fi
    echo
    echo "Getting the recommended server... "
    echo
    if [[ "$killswitch" == "enabled" ]] && [[ "$connected" != "connected" ]]; then
        echo -e "The VPN is $connectedc with the Kill Switch $killswitchc."
        echo
        bestserver=""
    else
        bestserver="$(timeout 10 curl --silent 'https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations' | jq --raw-output '.[0].hostname' | awk -F. '{print $1}')"
    fi
    if [[ "$bestserver" == "" ]]; then
        echo "Request timed out. Using 'nordvpn connect'"
    else
        echo -e "Connecting to ${LColor}$bestserver${Color_Off}"
    fi
    echo
    nordvpn connect $bestserver
    status
    exit
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
    discon2
    status
    exit
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
        read -n 1 -s -r -p "Press any key for the menu... "
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
    # "nordvpn connect Melbourne".  That's it.
    #
    # An almost unlimited number of menu items can be added.
    # Submenu items can be copied to the main menu for easier access.
    #
    PS3=$'\n''Choose an option: '
    #
    mainmenu=("Vancouver" "Seattle" "Los_Angeles" "Atlanta" "Sweden" "Japan" "US_Cities" "CA_Cities" "Discord" "QuickConnect" "Countries" "Groups" "Settings" "Disconnect" "Exit")
    #
    nummainmenu=${#mainmenu[@]}
    select opt in "${mainmenu[@]}"
    do
        case $opt in
            "Vancouver")
                discon
                #set_defaults    # Apply default settings for this connection.
                nordvpn connect Vancouver
                status
                break
                ;;
            "Seattle")
                discon
                nordvpn connect Seattle
                status
                break
                ;;
            "Los_Angeles")
                discon
                nordvpn connect Los_Angeles
                status
                break
                ;;
            "Atlanta")
                discon
                nordvpn connect Atlanta
                status
                break
                ;;
            "Sweden")
                discon
                nordvpn connect Sweden
                status
                break
                ;;
            "Japan")
                discon
                nordvpn connect Japan
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
            "Discord")
                # I use this entry to connect to a specific server which can help
                # avoid repeat authentication requests. It then opens a URL.
                # It may be useful for other sites or applications.
                # Example: NordVPN discord  https://discord.gg/83jsvGqpGk
                heading "Discord"
                discon2
                echo
                echo "Connect to us8247 for Discord"
                echo
                nordvpn connect us8247
                status
                xdg-open https://discord.gg/83jsvGqpGk  # default browser
                # /usr/bin/firefox --new-window https://discord.gg/83jsvGqpGk
                break
                ;;
            "QuickConnect")
                # alternative to "nordvpn connect"
                fquickconnect
                ;;
            "Hostname")
                # can add to mainmenu
                fhostname
                ;;
            "Countries")
                fcountries
                ;;
            "Groups")
                # submenu for groups
                heading "Groups"
                echo
                PS3=$'\n''Choose a Group: '
                submgroups=("All_Groups" "Obfuscated" "Double-VPN" "Onion+VPN" "P2P" "Exit")
                numsubmgroups=${#submgroups[@]}
                select smg in "${submgroups[@]}"
                do
                    case $smg in
                        "All_Groups")
                            fallgroups
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
                            echo
                            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                            echo
                            echo "Select any number from 1-$numsubmgroups ($numsubmgroups to Exit)."
                            ;;
                    esac
                done
                ;;
            "Settings")
                # submenu for settings
                heading "Settings"
                echo
                echo -e "$techpro$fw$ks$cs$ob$no$ac$ip6$dns$fst"
                echo
                PS3=$'\n''Choose a Setting: '
                submsett=("Technology" "Protocol" "Firewall" "KillSwitch" "CyberSec" "Obfuscate" "Notify" "AutoConnect" "IPv6" "Custom-DNS" "Whitelist" "Account" "Restart" "Reset" "IPTables" "Tools" "Script" "Defaults" "Exit")
                numsubmsett=${#submsett[@]}
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
                        "CyberSec")
                            fcybersec
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
                            echo
                            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                            echo
                            echo "Select any number from 1-$numsubmsett ($numsubmsett to Exit)."
                            ;;
                    esac
                done
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
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$nummainmenu ($nummainmenu to Exit)."
                main_menu
                ;;
        esac
    done
    exit
}
#
echo
echo "Bash Version $BASH_VERSION"
if (( BASH_VERSINFO < 4 )); then
    echo -e "${WColor}Bash v4.0 or higher is required.${Color_Off}"
    echo
    exit 1
fi
#
if ! command -v nordvpn &> /dev/null; then
    echo -e "${WColor}The NordVPN Linux client could not be found.${Color_Off}"
    echo "https://nordvpn.com/download/"
    echo
    exit 1
else
    nordvpn --version
    echo
fi
#
if ! systemctl is-active --quiet nordvpnd; then
    echo -e "${WColor}nordvpnd.service is not active${Color_Off}"
    echo -e "${EColor}Starting the service... ${Color_Off}"
    echo "sudo systemctl start nordvpnd.service"
    sudo systemctl start nordvpnd.service; wait
    echo
fi
# Update notice
numupdate=$( nordvpn status | grep -i "update" | tr -d '-' | wc -w )
numtail=$(( $numupdate + 3 ))
#
if (( $numupdate > 0 )); then
    echo -e "${WColor}** A NordVPN update is available **${Color_Off}"
    echo
    echo -e "${LColor}Before updating:${Color_Off}"
    echo "nordvpn set killswitch disabled"
    echo "nordvpn set autoconnect disabled"
    echo "nordvpn disconnect"
    echo
    echo
    read -n 1 -s -r -p "Press any key for the menu... "
    echo
fi
#
main_menu start
#
# =====================================================================
# Notes
#
# Add repository and install:
#   https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
#   sudo apt install /path/to/nordvpn-release_1.0.0_all.deb
#   sudo apt update
#   sudo apt install nordvpn
#
# Alternate install method:
#   sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
#   or
#   sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh)
#
# To reinstall:
#   sudo apt update
#   sudo apt autoremove --purge nordvpn*
#   delete: /home/username/.config/nordvpn/nordvpn.conf
#   sudo apt install nordvpn
#
# To downgrade:
#   sudo apt update
#   sudo apt autoremove --purge nordvpn*
#   delete: /var/lib/nordvpn/           # (should already be deleted)
#   delete: /home/username/.config/nordvpn/
#   apt-cache showpkg nordvpn
#   sudo apt install nordvpn=3.12.0-1   # (for example)
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
# "nordvpn login --nordaccount" will become the default login method
#
# NordLynx stability issues
#   install WireGuard
#
# Other Troubleshooting
#   systemctl status nordvpnd.service
#   systemctl status nordvpn.service
#   journalctl -u nordvpnd.service
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
# NordVPN Indicator Cinnamon Applet - no status with Nord update notice
#   ~/.local/share/cinnamon/applets/nordvpn-indicator@nickdurante/applet.js
#   Line 111 - Change [0] to [1]
#       let result = status.split("\n")[1].split(": ")[1];
#
