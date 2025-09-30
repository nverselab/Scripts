#!/bin/sh 

# Get current signed-in user 
currentUser=$(ls -l /dev/console | awk '/ / { print $3 }') 

# com.jamf.connect.state.plist location 
jamfConnectStateLocation="/Users/$currentUser/Library/Preferences/com.jamf.connect.state.plist" 

# Check if the plist file exists 
if [ -f "$jamfConnectStateLocation" ]; then 
	
	# Read DisplayName from the plist file 
	DisplayName=$(/usr/libexec/PlistBuddy -c "Print :DisplayName" "$jamfConnectStateLocation" 2>/dev/null) 
	
	if [ -n "$DisplayName" ]; then 
		
		# Upload DisplayName to Jamf Pro if it's not empty 
		if [ "$currentUser" != "root" ]; then 
			/usr/local/bin/jamf recon -endUsername "$DisplayName" 
		fi 
		
	else echo "DisplayName not found in $jamfConnectStateLocation" 
	fi 
	
else echo "Plist file not found: $jamfConnectStateLocation" 
fi 

exit 0
