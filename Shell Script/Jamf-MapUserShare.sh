#!/bin/bash

# Make sure to set the base share path to parameter 4 in your Jamf Pro policy (example: smb://path/to/root/users/directory)

# Variables
username=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
shareURL="$4/$username"
shareName="$username" # Base name of the share, used for finding the mount point
linkLocation="/Users/$username/Desktop/Home"

# Prompt the user for their network password using a graphical dialog
password=$(osascript <<EOF
tell application "System Events"
    display dialog "Please enter your password for accessing the network share ($shareURL):" default answer "" with hidden answer
    return text returned of result
end tell
EOF
)

# Attempt to mount the SMB share
echo "Attempting to mount the SMB share..."
osascript <<EOF
tell application "Finder"
    try
        mount volume "$shareURL" as user name "$username" with password "$password"
    on error errMsg
        display dialog "Failed to mount: " & errMsg
    end try
end tell
EOF

# Dynamically find the mounted volume's path
mountPoint=$(ls /Volumes | grep -m 1 "^$shareName" | while read name; do echo "/Volumes/$name"; done)

if [ -n "$mountPoint" ] && [ -d "$mountPoint" ]; then
    echo "Found mounted volume at $mountPoint"
    
    # Ensure the link location does not already exist
    if [ -e "$linkLocation" ]; then
        echo "The link location already exists. Removing existing link/directory..."
        rm -rf "$linkLocation"
    fi
    
    # Create the symbolic link
    ln -s "$mountPoint" "$linkLocation"
    echo "Symbolic link created at $linkLocation"
else
    echo "Error: Mount point for $shareName does not exist. Ensure the SMB share is mounted."
fi
