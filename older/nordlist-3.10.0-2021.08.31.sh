#!/bin/bash
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added a
# lot of comments to help fellow newbies customize the script.
#
# It looks like this:
# https://i.imgur.com/MzCGqDX.png
# https://i.imgur.com/Qo432W8.png
# https://i.imgur.com/liy5O0q.png
#
# /u/pennyhoard20 on reddit
# https://github.com/ph202107/nordlist
#
# Last tested with NordVPN Version 3.10.0 on Linux Mint 20.1
# (Bash 5.0.17) August 31 2021
#
# =====================================================================
# Instructions
# 1) Save as nordlist.sh
#       For convenience I use a directory in my PATH (echo $PATH)
#       eg. /home/username/bin/nordlist.sh
# 2) Make the script executable with
#       "chmod +x nordlist.sh"
# 3) For the customized menu ASCII and to generate ASCII headings two
#    small programs are required *
#    "figlet" (ASCII generator) and "lolcat" (for coloring).
#    eg. "sudo apt-get install figlet && sudo apt-get install lolcat"
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
# "curl" and "jq"   Settings-Tools-NordVPN API  (function nordapi)
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
# Specify your P2P preferred country.  eg p2pwhere="Canada"
p2pwhere=""
#
# Specify your Obfuscated_Servers preferred country.
# The location must support obfuscation.  eg obwhere="United_States"
obwhere=""
#
# Specify your Auto-Connect location.  eg acwhere="Canada Toronto"
# When obfuscate is enabled, the location must support obfuscation.
acwhere=""
#
# Specify your Custom DNS servers with a description.
# See "function fcustomdns" for third party servers already listed.
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
# Adjust the COLUMNS value if the menu looks jumbled or to
# match your terminal.
COLUMNS=80
#
# =====================================================================
# FAST options speed up the script by automatically answering 'yes'
# to prompts.  Would recommend trying the script to see how it operates
# before enabling these options.
#
# Choose "y" or "n"
#
# Return to the main menu without prompting "Press any key...".
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
# After choosing a country, automatically connect to the city if
# there is only one choice.
fast5="n"
#
# By default the [F] indicator will be set when any of the 'fast'
# options are enabled.
# Modify 'allfast' if you want to display the [F] indicator only when
# specific 'fast' options are enabled.
allfast=( "$fast1" "$fast2" "$fast3" "$fast4" "$fast5" )
#
# =====================================================================
# The Main Menu starts on line 1691.  Recommend configuring the
# first six main menu items to suit your needs.
#
# Add your Whitelist configuration commands to "function fwhitelist".
# Configure "function set_defaults" to set up a default NordVPN config.
#
# Change the main menu figlet ASCII style in "function custom_ascii"
# Change the figlet ASCII style for headings in "function heading"
# Change the highlighted text and indicator colors under "COLORS"
#
# Note: The "Restart" menu option will ask for a sudo password
# - see "function frestart"
#
# ==End================================================================
#
# COLORS (BOLD) - (must use "echo -e")
#
BBlack='\033[1;30m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BBlue='\033[1;34m'
BPurple='\033[1;35m'
BCyan='\033[1;36m'
BWhite='\033[1;37m'
#
Color_Off='\033[0m'
#                       # Change colors here if needed.
EColor=${BGreen}        # Color for Enabled/On indicator
DColor=${BRed}          # Color for Disabled/Off indicator
WColor=${BRed}          # Color for warnings, errors, disconnects
LColor=${BCyan}         # Color for "changes" lists and key info text
FColor=${BYellow}       # Color for 'fast' indicator and text
TColor=${BPurple}       # Technology and Protocol indicator and text
#
#
function std_ascii {
# This ASCII can display above the main menu if you
# prefer to use other ASCII art.
# Place any ASCII art between cat << "EOF" and EOF
# and specify std_ascii in "function logo".
cat << "EOF"
 _   _               ___     ______  _   _
| \ | | ___  _ __ __| \ \   / /  _ \| \ | |
|  \| |/ _ \| '__/ _' |\ \ / /| |_) |  \| |
| |\  | (_) | | | (_| | \ V / |  __/| |\  |
|_| \_|\___/|_|  \__,_|  \_/  |_|   |_| \_|

EOF
}
function custom_ascii {
    # This is the customized ASCII generated by figlet, displayed above the main menu.
    # Specify custom_ascii in "function logo".
    # Any text or variable can be used, single or multiple lines.
    if [[ "$connected" == "Connected" ]]; then
        #figlet NordVPN                         # standard font in mono
        #figlet NordVPN | lolcat -p 0.8         # standard font colorized
        #figlet -f slant NordVPN | lolcat       # slant font, colorized
        #figlet $city | lolcat -p 1             # display the city name, more rainbow
        figlet -f slant $city | lolcat -p 2    # city in slant font
        #figlet $country | lolcat -p 1.5        # display the country
        #figlet $transferd | lolcat  -p 1       # display the download statistic
        #
    else
        figlet NordVPN                          # style when disconnected
    fi
}
function logo {
    set_vars
    #
    # Specify  std_ascii or custom_ascii on the line below.
    custom_ascii
    #
    echo $connected: $city $country $server $ip
    echo -e $techpro$fw$ks$cs$ob$no$ac$ip6$dns$fst
    echo -e $transfer $uptime
    echo
    # all indicators: $techpro$fw$ks$cs$ob$no$ac$ip6$dns$fst
}
function heading {
    clear -x
    # This is the ASCII that displays after a menu selection is made.
    #
    # Uncomment the next two lines if figlet is not installed
    #echo ""; echo -e "${EColor}/// $1 ///${Color_Off}"; echo ""
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
        echo -e "${EColor}/// $1 ///${Color_Off}"
        echo
    fi
}
function fwhitelist {
    heading "Whitelist"
    echo "Edit the script to add your whitelist commands to"
    echo -e "${LColor} 'function fwhitelist' ${Color_Off}"
    echo
    echo "This option may be useful to restore a default whitelist"
    echo "configuration after using 'Reset' or making other changes."
    echo
    read -n 1 -r -p "Apply your default whitelist settings? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Enter one command per line.  Example:
        #
        #nordvpn whitelist remove all    # Clear the Whitelist
        #nordvpn whitelist add subnet 192.168.1.0/24
        #
        echo
    else
        echo
        echo "No changes made."
    fi
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
    if [[ "$technology" == "NordLynx" ]]; then
        nordvpn set technology OpenVPN
        set_vars    # to set $protocol and $obfuscate
    fi
    if [[ "$protocol" == "TCP" ]]; then
        nordvpn set protocol UDP
    fi
    if [[ "$firewall" == "disabled" ]]; then
        nordvpn set firewall enabled
    fi
    if [[ "$killswitch" == "enabled" ]]; then
        nordvpn set killswitch disabled
    fi
    if [[ "$cybersec" == "disabled" ]]; then
        nordvpn set cybersec enabled
    fi
    if [[ "$obfuscate" == "enabled" ]]; then
        nordvpn set obfuscate disabled
    fi
    if [[ "$notify" == "enabled" ]]; then
        nordvpn set notify disabled
    fi
    if [[ "$autocon" == "enabled" ]]; then
        nordvpn set autoconnect disabled
        #nordvpn set autoconnect enabled $acwhere
    fi
    if [[ "$ipversion6" == "enabled" ]]; then
        nordvpn set ipv6 disabled
    fi
    # dns and whitelist commands
    echo
    echo -e "${LColor}Default configuration applied.${Color_Off}"
    echo
}
#
# =====================================================================
#
function nstatbl {  # search "status" array by line
    printf '%s\n' "${nstat[@]}" | grep -i "$1"
}
function nsetsbl {  # search "settings" array by line
    printf '%s\n' "${nsets[@]}" | grep -i "$1"
}
function set_vars {
    #
    # VARIABLES
    #
    # Store info in arrays (BASH v4)
    readarray -t nstat < <( nordvpn status | tr -d '\r' )
    readarray -t nsets < <( nordvpn settings | tr -d '\r' )
    #
    # Exit if an update is available.
    # (Variables won't be set correctly with an update notice.)
    if nstatbl "update"; then
        echo
        echo -e "${WColor}** Please update NordVPN. **${Color_Off}"
        echo
        exit
    fi
    #
    # "nordvpn status" - array nstat - search function nstatbl
    # When disconnected, $connected is the only variable from nstat
    connected=$(nstatbl "Status" | awk '{ print $4 }')
    nordhost=$(nstatbl "Current server" | cut -f3 -d' ') # full hostname
    server=$(echo "$nordhost" | cut -f1 -d'.')           # shortened hostname
    # country and city names may have spaces eg. "United States"
    country=$(nstatbl "Country" | cut -f2 -d':' | cut -c 2-)
    city=$(nstatbl "City" | cut -f2 -d':' | cut -c 2-)
    ip=$(nstatbl "Server IP" | cut -f 2-3 -d' ')        # includes "IP: "
    ipaddr=$(echo "$ip" | cut -f2 -d' ')                # IP address only
    technology2=$(nstatbl "technology" | cut -f3 -d' ')
    protocol2=$(nstatbl "protocol" | cut -f3 -d' ')
    transferd=$(nstatbl "Transfer" | cut -f 2-3 -d' ')  # download stat with units
    transferu=$(nstatbl "Transfer" | cut -f 5-6 -d' ')  # upload stat with units
    transfer="\u25bc $transferd  \u25b2 $transferu"     # unicode up/down arrows
    uptime=$(nstatbl "Uptime" | cut -f 1-5 -d' ')
    #
    # "nordvpn settings" - array nsets - search function nsetsbl
    technology=$(nsetsbl "Technology" | awk '{ print $4 }')
    protocol=$(nsetsbl "Protocol" | cut -f2 -d' ')      # not listed when using NordLynx
    firewall=$(nsetsbl "Firewall" | cut -f2 -d' ')
    killswitch=$(nsetsbl "Kill" | cut -f3 -d' ')
    cybersec=$(nsetsbl "CyberSec" | cut -f2 -d' ')
    obfuscate=$(nsetsbl "Obfuscate" | cut -f2 -d' ')    # not listed when using NordLynx
    notify=$(nsetsbl "Notify" | cut -f2 -d' ')
    autocon=$(nsetsbl "Auto" | cut -f2 -d' ')
    ipversion6=$(nsetsbl "IPv6" | cut -f2 -d' ')
    dns_set=$(nsetsbl "DNS" | cut -f2 -d' ')        # disabled or not=disabled
    dns_srvrs=$(nsetsbl "DNS")                      # Server IPs, includes "DNS: "
    #
    # To display the protocol for either Technology whether connected or disconnected.
    if [[ "$connected" == "Connected" ]]; then
        protocold=$protocol2
    elif [[ "$technology" == "NordLynx" ]]; then
        protocold="UDP"
    else
        protocold=$protocol
    fi
    #
    # Status Indicators
    #
    # technology and protocol
    techpro=(${TColor}"[$technology $protocold]"${Color_Off})
    #
    if [[ "$firewall" == "enabled" ]]; then
        fw=(${EColor}[FW]${Color_Off})
    else
        fw=(${DColor}[FW]${Color_Off})
    fi
    #
    if [[ "$killswitch" == "enabled" ]]; then
        ks=(${EColor}[KS]${Color_Off})
    else
        ks=(${DColor}[KS]${Color_Off})
    fi
    #
    if [[ "$cybersec" == "enabled" ]]; then
        cs=(${EColor}[CS]${Color_Off})
    else
        cs=(${DColor}[CS]${Color_Off})
    fi
    #
    if [[ "$obfuscate" == "enabled" ]]; then
        ob=(${EColor}[OB]${Color_Off})
        obfuscatec=(${EColor}"$obfuscate"${Color_Off})
        obprompt=$(echo -e "${DColor}Disable${Color_Off} Obfuscate? (y/n) ")
    else
        ob=(${DColor}[OB]${Color_Off})
        obfuscatec=(${DColor}"$obfuscate"${Color_Off})
        obprompt=$(echo -e "${EColor}Enable${Color_Off} Obfuscate? (y/n) ")
    fi
    #
    if [[ "$notify" == "enabled" ]]; then
        no=(${EColor}[NO]${Color_Off})
    else
        no=(${DColor}[NO]${Color_Off})
    fi
    #
    if [[ "$autocon" == "enabled" ]]; then
        ac=(${EColor}[AC]${Color_Off})
    else
        ac=(${DColor}[AC]${Color_Off})
    fi
    #
    if [[ "$ipversion6" == "enabled" ]]; then
        ip6=(${EColor}[IP6]${Color_Off})
    else
        ip6=(${DColor}[IP6]${Color_Off})
    fi
    #
    if [[ "$dns_set" == "disabled" ]]; then # reversed
        dns=(${DColor}[DNS]${Color_Off})
    else
        dns=(${EColor}[DNS]${Color_Off})
    fi
    #
    if [[ ${allfast[@]} =~ [Yy] ]]; then
        fst=(${FColor}[F]${Color_Off})
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
    if [[ "$connected" == "Connected" ]]; then
        echo
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
    if [[ "$connected" == "Connected" ]]; then
        echo
        echo -e "${WColor}** Disconnect **${Color_Off}"
        echo
        nordvpn disconnect; wait
        echo
    fi
    echo
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
        if [[ "$connected" == "Connected" ]] && [[ "$exitping" =~ ^[Yy]$ ]]; then
            sleep 1  # on rare occasions ping doesn't work if sent too soon
            ping -c 3 -q $nordhost
            echo
            server_load
        fi
    fi
    date
    echo
}
function warning {
    set_vars
    if [[ "$connected" == "Connected" ]]; then
        echo -e "${WColor}** Changing this setting will disconnect the VPN **${Color_Off}"
        echo
    fi
}
function main_menu {
    # To always show the logo with updated info above the main menu.
    # (should not create more processes)
    if [[ ! "$fast1" =~ ^[Yy]$ ]]; then
        echo
        echo
        read -n 1 -s -r -p "Press any key for the menu... "
    fi
    exec bash "$0" "$@"
}
function fcountries {
    # submenu for all available countries and cities
    heading "Countries"
    countrylist=($(nordvpn countries | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | sort | tail -n +3))
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
    # all available cities.  called from function fcountries
    heading "$xcountry"
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Cities in $xcountry with Obfuscation support"
        echo
    fi
    if [[ "$xcountry" == "Sarajevo" ]]; then  # special case
        xcountry="Bosnia_and_Herzegovina"
    fi
    citylist=($(nordvpn cities $xcountry | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | sort | tail -n +3))
    citylist+=( "Default" )
    citylist+=( "Exit" )
    numcities=${#citylist[@]}
    if [[ "$numcities" == "3" ]] && [[ "$fast5" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${FColor}[F]ast5 option is enabled.${Color_Off}"
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
            nordvpn connect $xcountry $xcity
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
function fallgroups {
    # submenu for all available groups
    heading "All Groups"
    grouplist=($(nordvpn groups | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | sort | tail -n +3))
    grouplist+=( "Exit" )
    numgroups=${#grouplist[@]}
    echo "Groups that are available with"
    echo
    echo -e "Technology: ${TColor}$technology${Color_Off}"
    if [[ "$technology" == "OpenVPN" ]]; then
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
        if [[ "$firewall" == "disabled" ]]; then
            echo -e "${WColor}The Firewall must be enabled to use the Kill Switch.${Color_Off}"
            echo
        fi
        change_setting "the Kill Switch" "$killswitch" "killswitch" "$ks" "override"
        echo
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
        echo -e "${FColor}[F]ast4 option is enabled.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "NordLynx" ]]; then
            nordvpn set technology OpenVPN; wait
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
        echo -e "${FColor}[F]ast4 option is enabled.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "NordLynx" ]]; then
            nordvpn set technology OpenVPN; wait
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
    echo "Set the protocol (for OpenVPN)."
    echo "Set Obfuscate to disabled."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the Onion_Over_VPN group."
    echo -e ${Color_Off}
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 option is enabled.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "OpenVPN" ]]; then
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
    echo "Set Obfuscate to disabled."
    echo "Change Protocol to UDP (choice)."
    echo "Enable the Kill Switch (choice)."
    echo "Connect to the P2P group $p2pwhere"
    echo -e ${Color_Off}
    if [[ "$fast4" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast4 option is enabled.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "Proceed? (y/n) "
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
        fi
        if [[ "$protocol" == "TCP" ]]; then
            ask_protocol
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
    echo -e "Currently using ${TColor}$technology${Color_Off}."
    echo
    if [[ "$fast3" =~ ^[Yy]$ ]]; then
        echo -e "${FColor}[F]ast3 option is enabled.${Color_Off}"
        REPLY="y"
    elif [[ "$technology" == "OpenVPN" ]]; then
        read -n 1 -r -p "Change the Technology to NordLynx? (y/n) "
    else
        read -n 1 -r -p "Change the Technology to OpenVPN? (y/n) "
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "OpenVPN" ]]; then
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
                echo
            fi
            if [[ "$protocol" == "TCP" ]]; then
                nordvpn set protocol UDP; wait
                echo
            fi
            nordvpn set technology NordLynx; wait
        else
            nordvpn set technology OpenVPN; wait
            ask_protocol
        fi
    else
        echo
        echo -e "Continue to use ${TColor}$technology${Color_Off}."
        echo
    fi
    if [[ "$1" == "obback" ]]; then
        set_vars
        fobfuscate
    fi
    main_menu
}
function fprotocol {
    # NordLynx = UDP only
    heading "Protocol"
    if [[ "$technology" == "NordLynx" ]]; then
        echo
        echo -e "Technology is currently set to ${TColor}NordLynx${Color_Off}."
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
            echo -e "${FColor}[F]ast3 option is enabled.${Color_Off}"
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
    echo
    echo -e "The Protocol is set to ${TColor}$protocol${Color_Off}."
    echo
    if [[ "$protocol" == "UDP" ]]; then
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
    # Firewall, KillSwitch, CyberSec, Notify, AutoConnect, IPv6
    # $1 name                       Auto-Connect
    # $2 variable enabled/disabled  $autocon
    # $3 Nord command               autoconnect
    # $4 indicator                  $ac
    # $5 override                   disable fast2 and main_menu
    # $6 location                   $acwhere
    #
    if [[ "$2" == "enabled" ]]; then
        VColor=${EColor}
        chgprompt=$(echo -e "${DColor}Disable${Color_Off} $1? (y/n) ")
    else
        VColor=${DColor}
        chgprompt=$(echo -e "${EColor}Enable${Color_Off} $1? (y/n) ")
    fi
    echo -e "$4 $1 is ${VColor}$2${Color_Off}."
    echo
    if [[ "$fast2" =~ ^[Yy]$ ]] && [[ "$5" != "override" ]]; then
        echo -e "${FColor}[F]ast2 option is enabled.${Color_Off}"
        REPLY="y"
    else
        read -n 1 -r -p "$chgprompt"
    fi
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$2" == "disabled" ]]; then
            if [[ "$3" == "cybersec" ]] && [[ "$dns_set" != "disabled" ]]; then
                nordvpn set dns disabled; wait
                echo
            fi
            if [[ "$3" == "autoconnect" ]]; then
                echo -e "Enable $1 ${LColor}$6${Color_Off}"
                echo
            fi
            if [[ "$3" == "killswitch" ]] && [[ "$firewall" == "disabled" ]]; then
                # when connecting to Groups
                echo -e "${WColor}Enabling the Firewall.${Color_Off}"
                echo
                nordvpn set firewall enabled; wait
                echo
            fi
            nordvpn set $3 enabled $6; wait
        else
            nordvpn set $3 disabled; wait
        fi
    else
        echo
        echo -e "$4 Keep $1 ${VColor}$2${Color_Off}."
        echo
    fi
    if [[ "$5" == "override" ]]; then return; fi
    main_menu
}
function ffirewall {
    heading "Firewall"
    echo "Enable or Disable the NordVPN Firewall."
    echo "Enabling the Nord Firewall disables the Linux UFW."
    echo "The Firewall must be enabled to use the Kill Switch."
    echo
    if [[ "$firewall" == "enabled" ]] && [[ "$killswitch" == "enabled" ]]; then
        echo -e "$fw the Firewall is ${EColor}$firewall${Color_Off}."
        echo
        echo -e "${WColor}The Kill Switch must be disabled before disabling the Firewall.${Color_Off}"
        echo
        change_setting "the Kill Switch" "$killswitch" "killswitch" "$ks" "override"
        echo
        set_vars
        if [[ "$killswitch" == "enabled" ]]; then
            echo -e "$fw Keep the Firewall ${EColor}$firewall${Color_Off}."
            main_menu
        fi
    fi
    change_setting "the Firewall" "$firewall" "firewall" "$fw"
}
function fkillswitch {
    heading "Kill Switch"
    echo "Kill Switch is a feature helping you prevent unprotected access to"
    echo "the internet when your traffic doesn't go through a NordVPN server."
    echo
    echo "When the Kill Switch is enabled and the VPN is disconnected, your"
    echo "computer should not be able to access the internet."
    echo
    if [[ "$connected" != "Connected" ]]; then
        echo -e "The VPN is currently ${LColor}$connected${Color_Off}"
        echo
    fi
    if [[ "$firewall" == "disabled" ]]; then
        echo -e "$ks the Kill Switch is ${DColor}$killswitch${Color_Off}."
        echo
        echo -e "${WColor}The Firewall must be enabled to use the Kill Switch.${Color_Off}"
        echo
        change_setting "the Firewall" "$firewall" "firewall" "$fw" "override"
        echo
        set_vars
        if [[ "$firewall" == "disabled" ]]; then
            echo -e "$ks Keep the Kill Switch ${DColor}$killswitch${Color_Off}."
            main_menu
        fi
    fi
    change_setting "the Kill Switch" "$killswitch" "killswitch" "$ks"
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
    change_setting "CyberSec" "$cybersec" "cybersec" "$cs"
}
function fobfuscate {
    # Obfuscate not available when using NordLynx
    # must disconnect/reconnect to change setting
    heading "Obfuscate"
    if [[ "$technology" == "NordLynx" ]]; then
        echo -e "Technology is currently set to ${TColor}NordLynx${Color_Off}."
        echo
        echo "Obfuscation is not available when using NordLynx."
        echo "Change Technology to OpenVPN to use Obfuscation."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting and return? (y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ftechnology obback
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
            echo -e "${FColor}[F]ast3 option is enabled.${Color_Off}"
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
            ask_protocol
        else
            echo
            echo -e "$ob Keep Obfuscate $obfuscatec."
            echo
        fi
    fi
    main_menu
}
function fnotify {
    heading "Notify"
    echo
    echo "Send OS notifications when the VPN status changes."
    echo
    change_setting "Notify" "$notify" "notify" "$no"
}
function fautoconnect {
    heading "AutoConnect"
    echo "Automatically connect to the VPN on startup."
    echo
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob If obfuscate is enabled, the AutoConnect location"
        echo "must support obfuscation."
        echo
    fi
    if [[ "$autocon" == "disabled" ]] && [[ "$acwhere" != "" ]]; then
        echo -e "Auto-Connect location: ${LColor}$acwhere${Color_Off}"
        echo
    fi
    change_setting "Auto-Connect" "$autocon" "autoconnect" "$ac" "negative" "$acwhere"
}
function fipversion6 {
    heading "IPv6"
    echo "Enable or disable NordVPN IPv6 support."
    echo
    change_setting "IPv6" "$ipversion6" "ipv6" "$ip6"
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
    # submenu for NordVPN Account options
    heading "Account"
    echo
    PS3=$'\n''Choose an Option: '
    submacct=("Login" "Logout" "Account Info" "Register" "Nord Version" "Changelog" "Nord Manual" "Exit")
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
                zless -p$( nordvpn --version | cut -f3 -d' ' ) "$nordchangelog"
                # version numbers are not in order (latest release != last entry)
                #
                #zless +G "$nordchangelog"
                #zcat "$nordchangelog"
                # also here:
                #https://nordvpn.com/blog/nordvpn-linux-release-notes/
                ;;
            "Nord Manual")
                echo
                man nordvpn
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
    # "Restart" will ask for a sudo password to
    # send the commands that restart nordvpnd
    #
    #  troubleshooting
    #  systemctl status nordvpnd.service
    #  systemctl status nordvpn.service
    #  journalctl -u nordvpnd.service
    #  journalctl -xe
    #  sudo service network-manager restart
    #  sudo service nordvpnd restart
    #
    heading "Restart"
    echo
    echo "Restart nordvpn services."
    echo -e ${WColor}
    echo "Send commands:"
    echo "nordvpn set killswitch disabled"
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
            nordvpn set killswitch disabled; wait
            echo
        fi
        if [[ "$autocon" == "enabled" ]]; then
            change_setting "Auto-Connect" "$autocon" "autoconnect" "$ac" "override" "$acwhere"
        fi
        echo
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
        if [[ "$1" == "plusdefaults" ]]; then
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
        echo -e "${WColor}** Reminder **${Color_Off}"
        echo -e "${LColor}Reconfigure the Whitelist and other settings.${Color_Off}"
        echo
        read -n 1 -s -r -p "Press any key to restart services..."
        set_vars
        frestart plusdefaults
    fi
    main_menu
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
        if [[ $rating =~ ^[Xx]$ ]]; then
            break
        fi
        if [[ $rating == "" ]]; then
            break
        fi
        if (( 1 <= $rating )) && (( $rating <= 5 )); then
            echo
            nordvpn rate $rating
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
    echo "Checking the server load..."
    echo
    sload=$(curl --silent https://api.nordvpn.com/server/stats/$nordhost | jq .percent)
    if (( $sload <= 30 )); then
        echo -e "$nordhost load = ${EColor}$sload%${Color_Off}"
    elif (( $sload <= 60 )); then
        echo -e "$nordhost load = ${FColor}$sload%${Color_Off}"
    else
        echo -e "$nordhost load = ${DColor}$sload%${Color_Off}"
    fi
    echo
}
function nordapi {
    # submenu for NordVPN API calls
    heading "NordVPN API"
    echo
    echo "Some commands copied from"
    echo -e "${EColor}https://sleeplessbeastie.eu/2019/02/18/how-to-use-public-nordvpn-api/${Color_Off}"
    echo "Requires 'curl' and 'jq'"
    echo "Commands may take a few seconds to complete."
    if [[ "$connected" == "Connected" ]]; then
        echo
        echo -e "Connected to ${EColor}$server.nordvpn.com${Color_Off}"
    fi
    echo
    echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
    echo
    PS3=$'\n''API Call: '
    submapi=("Host Server Load" "Host Server Info" "Top 5 Recommended" "Top 5 By Country" "#Servers per Country" "All VPN Servers" "Change Host" "Exit")
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
            "Top 5 Recommended")
                echo
                echo -e "${LColor}Top 5 Recommended VPN Servers${Color_Off}"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations" | jq --raw-output 'limit(5;.[]) | "  Server: \(.name)\nHostname: \(.hostname)\nLocation: \(.locations[0].country.name) - \(.locations[0].country.city.name)\n    Load: \(.load)\n"'
                ;;
            "Top 5 By Country")
                echo
                echo -e "${LColor}Top 5 VPN Servers by Country Code${Color_Off}"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | [.id, .name] | @tsv'
                echo
                read -r -p "Country Code: " ccode
                echo
                echo "server: %load"
                echo
                curl --silent "https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=$ccode&\[servers_groups\]\[identifier\]=legacy_standard" | jq --raw-output --slurp ' .[] | sort_by(.load) | limit(5;.[]) | [.hostname, .load] | "\(.[0]): \(.[1])"'
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
                echo
                echo -e "${LColor}All the VPN Servers${Color_Off}"
                echo
                curl --silent https://api.nordvpn.com/server | jq --raw-output '.[].domain' | sort --version-sort
                echo
                ;;
            "Change Host")
                echo
                echo "Change the Hostname for testing purposes."
                if [[ "$connected" == "Connected" ]]; then
                    echo
                    echo -e "Connected to ${EColor}$server.nordvpn.com${Color_Off}"
                fi
                echo
                echo -e "Current Host: ${LColor}$nordhost${Color_Off}"
                echo
                echo "Choose a new Hostname/IP for testing"
                read -r -p "'Enter' for default [$default_host]: " nordhost
                nordhost=${nordhost:-$default_host}
                echo
                echo -e "Now using ${LColor}$nordhost${Color_Off} for testing."
                echo
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
function ftools {
    # submenu for Tools
    heading "Tools"
    if [[ "$connected" == "Connected" ]]; then
        echo "Connected to: $city $country"
        echo -e "Server: ${LColor}$nordhost${Color_Off}  IP: ${LColor}$ipaddr${Color_Off}"
        echo -e "$techpro$fw$ks$cs$ob$no$ac$ip6$dns$fst"
        echo -e "$transfer  $uptime"
        echo
        PS3=$'\n''Choose a tool: '
    else
        echo -e "${WColor}** VPN is Disconnected **${Color_Off}"
        echo
        read -r -p "Enter a Hostname/IP [Default $default_host]: " nordhost
        nordhost=${nordhost:-$default_host}
        echo
        echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
        echo "(Does not affect 'Rate VPN Server')"
        echo
        PS3=$'\n''Choose a tool (VPN Off): '
    fi
    nettools=("Rate VPN Server" "NordVPN API" "www.speedtest.net" "youtube-dl" "ping vpn" "ping google" "my traceroute" "ipleak.net" "world map" "Change Host" "Exit")
    numnettools=${#nettools[@]}
    select tool in "${nettools[@]}"
    do
        case $tool in
            "Rate VPN Server")
                rate_server
                ;;
            "NordVPN API")
                nordapi
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
                echo "ping -c 5 $nordhost"
                echo
                ping -c 5 $nordhost
                echo
                ;;
            "ping google")
                clear -x
                echo
                echo "Ping Google DNS 8.8.8.8, 8.8.4.4"
                echo "Ping Cloudflare DNS 1.1.1.1, 1.0.0.1"
                echo "Ping Telstra Australia 139.130.4.5"
                echo
                echo "(CTRL-C to quit)"
                echo
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
                echo
                echo "Change the Hostname for testing purposes."
                if [[ "$connected" == "Connected" ]]; then
                    echo
                    echo -e "Connected to ${EColor}$server.nordvpn.com${Color_Off}"
                fi
                echo
                echo -e "Host Server: ${LColor}$nordhost${Color_Off}"
                echo
                echo "Choose a new Hostname/IP for testing"
                read -r -p "'Enter' for default [$default_host]: " nordhost
                nordhost=${nordhost:-$default_host}
                echo
                echo -e "Now using ${LColor}$nordhost${Color_Off} for testing."
                echo "(Does not affect 'Rate VPN Server')"
                echo
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
    echo
    echo -e "${LColor}[Defaults]${Color_Off} Disconnect and apply the NordVPN settings"
    echo "specified in 'function set_defaults'."
    echo
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        set_defaults
        echo
        read -n 1 -r -p "$(echo -e "${LColor}[Defaults]${Color_Off} Go to the 'Whitelist' setting? (y/n) ")"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fwhitelist back
        fi
        echo
        read -n 1 -r -p "$(echo -e "${LColor}[Defaults]${Color_Off} Go to the 'CustomDNS' setting? (y/n) ")"
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
        xdg-open "$0"
        exit
    fi
}
function fdisconnect {
    heading "Disconnect"
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "${WColor}** Reminder **${Color_Off}"
        change_setting "the Kill Switch" "$killswitch" "killswitch" "$ks" "override"
    fi
    if [[ "$alwaysrate" =~ ^[Yy]$ ]]; then
        rate_server
    fi
    discon2
    status
    exit
}
#
# ====== MAIN MENU ====================================================
#
clear -x
logo
#
# To modify the list, for example changing Vancouver to Seattle:
# change "Vancouver" in both the first(horizontal) and second(vertical)
# list to "Seattle", and where it says
# "nordvpn connect Canada Vancouver" change it to
# "nordvpn connect United_States Seattle".  That's it.
#
PS3=$'\n''Choose an option: '
#
mainmenu=("Vancouver" "Toronto" "Montreal" "Canada" "USA" "Discord" "Countries" "Groups" "Settings" "Disconnect" "Exit")
#
nummainmenu=${#mainmenu[@]}
select opt in "${mainmenu[@]}"
do
    case $opt in
        "Vancouver")
            discon
            #set_defaults
            nordvpn connect Canada Vancouver
            status
            break
            ;;
        "Toronto")
            discon
            nordvpn connect Canada Toronto
            status
            break
            ;;
        "Montreal")
            discon
            nordvpn connect Canada Montreal
            status
            break
            ;;
        "Canada")
            discon
            nordvpn connect Canada
            status
            break
            ;;
        "USA")
            discon
            nordvpn connect United_States
            status
            break
            ;;
        "Discord")
            # I use this entry to connect to a specific server which can help
            # avoid repeat authentication requests. It then opens a URL.
            # It may be useful for other sites.
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
            submsett=("Technology" "Protocol" "Firewall" "KillSwitch" "CyberSec" "Obfuscate" "Notify" "AutoConnect" "IPv6" "Custom-DNS" "Whitelist" "Account" "Restart" "Reset" "Tools" "Script" "Defaults" "Exit")
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
