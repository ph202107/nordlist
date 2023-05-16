Unofficial bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).   
Fully customizable. 
Screenshots available in "screenshots" folder.  

To download:    
- Click on the green "Code" icon above
- Choose "Download Zip" 
- Extract "nordlist.sh"  

Then:   
- Make the script executable with "chmod +x nordlist.sh"
- Recommended: "sudo apt install figlet lolcat curl jq"
- Optional: "sudo apt install wireguard wireguard-tools speedtest-cli iperf3 highlight"
- Open the script in any text editor or IDE
- Configure the customization options at the beginning of the script

=========================================

NordVPN version 3.16.2 issues:

- Error when connecting to the Obfuscated_Servers Group.  
For example "nordvpn connect --group Obfuscated_Servers" responds with:   
"The specified group does not exist." 

Workaround - enable the 'Obfuscate' setting, and connect to supported locations using all lower-case letters.  For example "nordvpn connect atlanta" will work, "nordvpn connect Atlanta" will fail.
