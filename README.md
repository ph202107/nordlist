Unofficial bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).   
Fully customizable. 

Screenshots:  
https://i.imgur.com/k9pb5U4.png  
https://i.imgur.com/uPSgJUR.png  
https://i.imgur.com/S3djlU5.png  
https://i.imgur.com/c31ZwqJ.png  

To download:    
- Click on the green "Code" icon above
- Choose "Download Zip" 
- Extract "nordlist.sh"  

Then:   
- Make the script executable with "chmod +x nordlist.sh"
- Recommended: "sudo apt install figlet lolcat curl jq"
- Optional: "sudo apt install wireguard wireguard-tools speedtest-cli highlight"
- Open the script in any text editor or IDE
- Configure the customization options at the beginning of the script

=================================

NordVPN version 3.15.4 currently has this issue:

- When connecting to the Obfuscated_Servers Group:  
"The specified group does not exist."

Workaround - enable the 'Obfuscate' setting, and connect to supported locations using all lower-case letters.  For example "nordvpn connect atlanta" will work, "nordvpn connect Atlanta" will fail.

=================================

NordVPN versions 3.14.2, 3.15.0, 3.15.1, 3.15.2, 3.15.3 currently have these issues:

- When connecting to the Obfuscated_Servers Group:  
"The specified group does not exist."

- When connecting to any supported location with Obfuscate enabled:  
"The specified server is not available at the moment or does not support your connection settings."
