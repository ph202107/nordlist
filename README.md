** 
The NordVPN update 3.12.1 is not working correctly for me.

I've purged, deleted, reinstalled, and used the browser login.
Attempting to connect to any city produces the error message:
"flag provided but not defined: "

I'll continue to use 3.12.0 for now.

The update notice will no longer cause the script to exit, and
the menus for Countries, Cities, and Groups won't include 
the notice.
**

Bash script to use with the NordVPN Linux CLI.  
Requires bash version 4 or greater.  
Tested with Linux Mint only (Debian/Ubuntu base).

It looks like this:   
https://i.imgur.com/s2ul0Yh.png   
https://i.imgur.com/dKnK7u9.png   
https://i.imgur.com/To2BbUI.png   
https://i.imgur.com/077qYI3.png   

To download:    
- Click on the green "Code" icon above
- Choose "Download Zip" 
- Extract and rename "nordlist-******.sh" to "nordlist.sh"  

Or:
- Click on the "nordlist-******.sh" link above
- Then click on "Raw" on the right hand side
- Select-All and Copy
- Open your text editor and Paste
- Save as "nordlist.sh" (with "Line Ending" option = Unix/Linux LF)

Then:   
- Make the script executable with "chmod +x nordlist.sh"
- Recommended: "sudo apt-get install figlet lolcat curl jq highlight"
- Customization notes are included in the script

