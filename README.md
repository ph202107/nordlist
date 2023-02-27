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

=========================================

NordVPN versions 3.15.4, 3.15.5 currently have these issues:

- Error when connecting to the Obfuscated_Servers Group.  
For example "nordvpn connect --group Obfuscated_Servers" responds with:   
"The specified group does not exist." 

Workaround - enable the 'Obfuscate' setting, and connect to supported locations using all lower-case letters.  For example "nordvpn connect atlanta" will work, "nordvpn connect Atlanta" will fail.

- Error when connecting to known good servers by name (with the correct settings).  
For example "nordvpn connect us8253" responds with:   
"The specified server is not available at the moment or does not support your connection settings." 

This bug seems to occur after using Obfuscate or possibly when switching between OpenVPN TCP and NordLynx.  It can be fixed by purging and reinstalling the app.  (I use /other/nuclear.sh for this task.)
