#!/bin/bash

# WARNING: UNTESTED! Change $StagePath and $INSTALLERS with correct values.

# Source: https://derflounder.wordpress.com/2018/10/11/building-an-sap-gui-installer-for-macos/
# Requires JDK8 Installed First:
# 	Intel: https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252315_68ce765258164726922591683c51982c
# 	ARM: https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252313_68ce765258164726922591683c51982c

StagePath="/Users/Shared/JamfStage/sapgui"
INSTALLERS="$StagePath/platingui_810_11-80009301.jar"
INSTALL_PATH="/Applications/SAP Clients"
JAVA_HOME=$(/usr/libexec/java_home -v 1.8*)
JAVA_BIN="$JAVA_HOME/bin/java"
currentLoggedInUser="$(/usr/bin/stat -f%Su /dev/console 2>/dev/null || true)"
src="$StagePath/SAPGUILandscape.xml"
dest_dir="/Users/$currentLoggedInUser/Library/Preferences/SAP"
ERROR=0

# Validate the logged in user: must be non-empty and not root or mbsetup
if [[ -z "$currentLoggedInUser" || "$currentLoggedInUser" == "root" || "$currentLoggedInUser" == "mbsetup" ]]; then
	echo "ERROR! Not running with Logged In User"
	ERROR=2
	exit $ERROR
fi
IFS=$'\n'


if [[ -d "$JAVA_HOME" && -x "$JAVA_BIN" ]]; then

	for INSTALL in ${INSTALLERS}; do

		echo "Attempting to install $INSTALL …"
		"$JAVA_BIN" -jar "$INSTALL" –nogui –force –nodesktopicons –installdir "$INSTALL_PATH" >/dev/null 2>&1
	
		if [[ $? -ne 0 ]]; then
			echo"ERROR! Installation of $INSTALL failed"
			ERROR=1
			break
		else
			echo "Successfully installed $INSTALL"
		fi
	done

else
	echo "ERROR! Java not found"
	ERROR=1
fi

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
