# nordlist
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added a
# lot of comments to help fellow newbies customize the script.
#
# It looks like this:  https://imgur.com/a/3LMBATC
# /u/pennyhoard20 on reddit
#
# Last tested with NordVPN Version 3.10.0 on Linux Mint 19.3
# (Bash 4.4.20) June 2021
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
