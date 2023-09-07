#!/bin/bash

# Source: https://community.jamf.com/t5/jamf-pro/jamf-pro-migration/m-p/265359
# Alternative: https://github.com/jamf/ReEnroller

# pass user creds from policy
jamfUser=$4
jamfPass=$5
OldjssUrl=""
NewjssURL=""

# Get Mac serial number
mac_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
echo "Mac serial: $mac_serial"

# Curl to get Mac Jamf ID. Adding text()' will just return the Jamf ID without bracked info.
jamf_id=$(curl -sku "${jamfUser}:${jamfPass}" "${OldjssUrl}/JSSResource/computers/serialnumber/${mac_serial}" -X GET | xmllint --xpath '/computer/general/id/text()' -)
echo "Jamf ID: $jamf_id"

#Just opens the Jamf user-initiated enrollment site
#open $NewjssURL/enroll

# Curl to send command to remove MDM profile from the Mac
curl -sku "${jamfUser}:${jamfPass}" "${OldjssUrl}/JSSResource/computercommands/command/UnmanageDevice/id/${jamf_id}" -X POST

echo "Removing jamf binary and framework from Mac..."
# Removing Jamf binary and framework after the MDM has been removed
jamf removeframework

# Attempt to re-enroll using ADE (Requires correct MDM assignment in ABM/ASM)
sudo profiles renew -type enrollment

exit 0
