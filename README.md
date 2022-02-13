NordVPN Version 3.12.4 currently has these issues:

 - Problems connecting to any specific location while the Kill Switch is enabled.  
 - Problems connecting to Groups when specifying a location. 
 
 "The specified server is not available at the moment or does not support your connection settings."

- Notify setting is still broken (for the last 6 versions, since 3.11.0-1)
 
===================================

Bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).   
Fully customizable. 

It looks like this:   
https://i.imgur.com/iz0505v.png   
https://i.imgur.com/RFnQIib.png   
https://i.imgur.com/To2BbUI.png   
https://i.imgur.com/077qYI3.png   

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

