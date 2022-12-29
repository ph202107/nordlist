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

NordVPN versions 3.14.2, 3.15.0, 3.15.1, 3.15.2, 3.15.3 currently have these issues:

- When connecting to the Obfuscated_Servers Group:  
"The specified group does not exist."

- When connecting to any supported location with Obfuscate enabled:  
"The specified server is not available at the moment or does not support your connection settings."

=================================

NordVPN versions 3.12.4, 3.12.5, 3.13.0, 3.14.0, 3.14.1 have these issues:

 - Problems connecting to any specific location while the Kill Switch is enabled.  
 - Problems connecting to any specific location while Obfuscate is enabled.
 - Problems connecting to Groups when specifying a location. 
 - Problems connecting to Groups while the Kill Switch is enabled. 
 - The "Notify" setting has been broken for the last ten versions, since 3.11.0 (Sept 2021).

