Bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).   
Fully customizable. 

Screenshots:  
https://i.imgur.com/dQhOPWH.png  
https://i.imgur.com/tlbAxaf.png  
https://i.imgur.com/EsaXIqY.png  
https://i.imgur.com/c31ZwqJ.png  

To download:    
- Click on the green "Code" icon above
- Choose "Download Zip" 
- Extract "nordlist.sh"  

Then:   
- Make the script executable with "chmod +x nordlist.sh"
- Recommended: "sudo apt install figlet lolcat curl jq"
- Customization notes are included in the script

=================================

NordVPN versions 3.12.4, 3.12.5, 3.13.0, 3.14.0, 3.14.1 currently have these issues:

 - Problems connecting to any specific location while the Kill Switch is enabled.  
 - Problems connecting to any specific location while Obfuscate is enabled.
 - Problems connecting to Groups when specifying a location. 
 - Problems connecting to Groups while the Kill Switch is enabled. 
 - The "Notify" setting has been broken for the last ten versions, since 3.11.0 (Sept 2021).

