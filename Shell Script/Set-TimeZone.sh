#!/bin/bash

# short time zone list

name[1]="London (+0:00)"
zone[1]="Europe/London"

name[2]="US Atlantic (-5:00)"
zone[2]="America/New_York"

name[3]="US Central (-6:00)"
zone[3]="America/Chicago"

name[4]="US Mountain (-7:00)"
zone[4]="America/Denver"

name[5]="US Pacific (-8:00)"
zone[5]="America/Los_Angeles"

name[6]="Chennai (+5:30)"
zone[6]="Asia/Colombo"

# set up logging

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# get path to the current user's home folder
currentUserFolder=$( eval echo ~$( /usr/bin/logname ) )

# set log file path
logFile="$currentUserFolder/Library/Logs/$currentScript.log"

# functions
function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$logFile"
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$logFile"
	fi
}

# systemsetup and writes to /Library/Preferences require root privileges.
if [ "$(/usr/bin/id -u)" -ne 0 ]; then
	/usr/bin/osascript -e 'display alert "Administrator privileges are required to change the time zone. Run this script through Jamf Self Service or another root-run management tool."'
	exit 1
fi


# set the time zone manually

logresult "User is choosing a time zone manually."

# present the user the short list of time zones

listNames=$( /usr/bin/printf '%s\n' "${name[@]}" )

theCommand="choose from list (every paragraph of \"$listNames\") with prompt \"Choose your current time zone.\" OK button name \"OK\" cancel button name \"More Choices\" with title \"Set Time Zone\""
listChoice=$( /usr/bin/osascript -e "$theCommand" )

# determine which time zone the user selected from the list
choiceIndex=$( /usr/bin/sdiff <(/bin/echo "$listNames") <(/bin/echo "$listChoice") | /bin/cat -n | /usr/bin/grep -v "<" | /usr/bin/awk '{ print $1 }' )

if [[ "$listChoice" != false ]]; then # user has chosen a time zone from the short list

	chosenTimeZone="${zone[$choiceIndex]}"
	
else # user has requested to see more time zones
	
	# read system time zone list
	timeZoneList=$( /usr/sbin/systemsetup -listtimezones )

	# parse and list regions from time zone list
	timeZoneRegion=$( /bin/echo "$timeZoneList" | /usr/bin/grep / | /usr/bin/awk -F '( |/)' '{ print $2 }' | /usr/bin/sort | /usr/bin/uniq )
	theCommand="choose from list (every paragraph of \"$timeZoneRegion\") with prompt \"Choose your current world region.\" with title \"Set Time Zone\""
	selectedRegion=$( /usr/bin/osascript -e "$theCommand" )

	# parse and list cities for chosen region in time zone list
	timeZoneCity=$( /bin/echo "$timeZoneList" | /usr/bin/grep "$selectedRegion" | /usr/bin/awk -F '(\/)' '{ print $2 }' | /usr/bin/sort | /usr/bin/uniq )
	theCommand="choose from list (every paragraph of \"$timeZoneCity\") with prompt \"Choose the nearest city to you for world region $selectedRegion.\" with title \"Set Time Zone\""
	selectedCity=$( /usr/bin/osascript -e "$theCommand" )
	
	# set new time zone to Region/City format
	chosenTimeZone="$selectedRegion/$selectedCity"
	
fi


# disable setting time zone automatically
/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool False

# set the time zone manually to chosen time zone
/usr/sbin/systemsetup -settimezone "$chosenTimeZone"

logresult "Setting time zone to $chosenTimeZone." "Failed setting time zone to $chosenTimeZone."

# notify the user time zone has been set
theCommand="display dialog \"Your system is now set to $( date +%Z ) timezone.\" with title \"Set Time Zone\" buttons {\"OK\"} default button {\"OK\"}"
/usr/bin/osascript -e "$theCommand"

exit 0
