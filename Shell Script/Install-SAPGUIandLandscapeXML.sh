#!/bin/bash

StagePath="/Users/Shared/JamfStage/sapgui"
currentLoggedInUser="$(/usr/bin/stat -f%Su /dev/console 2>/dev/null || true)"
dest_dir="/Users/$currentLoggedInUser/Library/Preferences/SAP"
ERROR=0

# Copy SAPUILandscape.xml to the logged in user's preferences
if [[ ! -d "$dest_dir" ]]; then
	if ! mkdir -p "$dest_dir"; then
		echo "ERROR! Failed to create destination directory $dest_dir"
		ERROR=3
		exit $ERROR
	fi
fi

cp -p "$StagePath/SAPUILandscape.xml" "$dest_dir/SAPUILandscape.xml"

# chown the file to the current logged-in user
chown "$currentLoggedInUser" "$dest_dir/SAPUILandscape.xml" || true

exit $ERROR
