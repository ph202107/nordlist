Bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).   
Fully customizable. 

It looks like this:   
https://i.imgur.com/iz0505v.png   
https://i.imgur.com/RFnQIib.png   
https://i.imgur.com/To2BbUI.png   
https://i.imgur.com/5nUCFN7.png   

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

NordVPN versions 3.12.4, 3.12.5, and 3.13.0 currently have these issues:

 - Problems connecting to any specific location while the Kill Switch is enabled.  
 - Problems connecting to Groups when specifying a location. 
 - The "Notify" setting has been broken for the last 8 (eight) versions, since 3.11.0-1.

NordVPN v3.10.0-1 does not have any of these problems and nordlist.sh should also work fine using this downgraded version.  

Can easily downgrade* using /other/nuclear.sh if it's compatible with your distro.

(*) As of May 30 2022, v3.10.0-1 has been removed from the repository.  
https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/
