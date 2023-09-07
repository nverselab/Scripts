#!/bin/bash

# Source: https://community.jamf.com/t5/jamf-pro/jamf-pro-migration/m-p/265359
# Alternative: https://github.com/jamf/ReEnroller

# pass user creds from policy
jamfUser=$4
jamfPass=$5
OldjssUrl="required"
NewjssURL="required"
enrollInvitationID="optional"

########## Unenroll the Computer from old JSS server ##########

# Get Mac serial number
mac_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
echo "Mac serial: $mac_serial"

# Curl to get Mac Jamf ID. Adding text()' will just return the Jamf ID without bracked info.
jamf_id=$(curl -sku "${jamfUser}:${jamfPass}" "${OldjssUrl}/JSSResource/computers/serialnumber/${mac_serial}" -X GET | xmllint --xpath '/computer/general/id/text()' -)
echo "Jamf ID: $jamf_id"

# Curl to send command to remove MDM profile from the Mac
curl -sku "${jamfUser}:${jamfPass}" "${OldjssUrl}/JSSResource/computercommands/command/UnmanageDevice/id/${jamf_id}" -X POST

echo "Removing jamf binary and framework from Mac..."
# Removing Jamf binary and framework after the MDM has been removed
jamf removeframework

########## Re-Enroll the Computer to new JSS server ##########
# Instructions: Uncomment one of the desired enrollment workflows and comment out the other two.
# Check if $enrollInvitationID has a value or is not equal to "optional"

if [ -n "$enrollInvitationID" ] || [ "$enrollInvitationID" != "optional" ]; then

  echo "Enrollment Invitation ID is set. Opening Enrollment Invitation URL."

# Option 1: Enrollment Invtation URL (Automatically sets destination Site as configured and skips Enrollment Admin authentication)
  enrollmentURL="$NewjssURL/enroll?invitation=$enrollInvitationID"
  open $enrollmentURL

else

  echo "Enrollment Invitation ID not set. Opening generic Enroll URL."

# Option 2: Generic Enrollment URL (requires Jamf Admin with Enroll Permissions or user is in IdP group allowed to Enroll)
  # Opens the Enrollment Invitation URL 
  open $NewjssURL/enroll

fi

# Option 3: Attempt to re-enroll using ADE (Requires correct MDM assignment in ABM/ASM)
#sudo profiles renew -type enrollment

exit 0
