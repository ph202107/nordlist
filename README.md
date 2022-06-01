Bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).   
Fully customizable. 

It looks like this:   
https://i.imgur.com/l64Xexq.png  
https://i.imgur.com/SWMhqr2.png  
https://i.imgur.com/c4bcAbM.png  
https://i.imgur.com/c64XSn8.png  

To download:    
- Click on the green "Code" icon above
- Choose "Download Zip" 
- Extract "nordlist.sh"  

Or:
- Click on the "nordlist.sh" link above
- Then click on "Raw" on the right hand side
- Select-All and Copy
- Open your text editor and Paste
- Save as "nordlist.sh" (with "Line Ending" option = Unix/Linux LF)

Then:   
- Make the script executable with "chmod +x nordlist.sh"
- Recommended: "sudo apt install figlet lolcat curl jq"
- Customization notes are included in the script

=================================

NordVPN versions 3.12.4, 3.12.5, 3.13.0, 3.14.0 currently have these issues:

 - Problems connecting to any specific location while the Kill Switch is enabled.  
 - Problems connecting to Groups when specifying a location. 
 - The "Notify" setting has been broken for the last 9 (nine) versions, since 3.11.0 (Sept 2021).

=================================

v3.14 - "CyberSec" changed to "Threat Protection Lite"  
To use this script with an older version (v3.13-) of the NordVPN Linux CLI:  
- modify "cybersec=" in "function set_vars"
