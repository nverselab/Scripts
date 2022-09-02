#!/bin/bash
### Use this script to remove the prior management vendor. ###
### This script runs after premigration script and before midmigration script. ###

DEPNOTIFYLOG="/private/var/tmp/depnotify.log"

echo "Status: Removing previous management..." >> $DEPNOTIFYLOG

/usr/local/bin/jamf removeFramework

exit 0
