#!/bin/bash

# NOTE: This is currently a work in progress.  Not production ready.

originurl="https://xxxx.awmdm.com/api" # The WS1 API URL of source environment
wsoClientID="required" # Base64 encoded API credentials for the source WS1 tenant
wsoSecret="required" # 	REST API token for the source WS1 tenant
NewjssURL="required" # The URL of the new JSS server (e.g. https://yourSubDomain.jamfcloud.com)
enrollInvitationID="optional"
serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`


# Function to unenroll device from ws1 by serial number
# Source: https://github.com/euc-oss/euc-samples/blob/main/UEM-Samples/Utilities%20and%20Tools/macOS/Migration-Tool/migrationToolWS1/payload/Library/Application%20Support/VMware/migrator.sh
removeWS1() {
  echo "Removing Workspace ONE UEM"
  # Make sure the Intelligent Hub uninstall script exists
if  [[ -e /Library/Scripts/hubuninstaller.sh ]]; then
    # Use it to uninstall Intelligent Hub
    echo "Uninstalling Intelligent Hub."
    /bin/bash /Library/Scripts/hubuninstaller.sh
else
    echo "Intelligent Hub uninstall script is missing; deleting the application to trigger reinstall."
    /bin/rm -rf /Applications/Workspace\ ONE\ Intelligent\ Hub.app/
fi
  /bin/rm -rf "/Library/Application Support/AirWatch/"
  # API Call to enterprise wipe device
  url="$originurl/api/mdm/devices/commands?command=EnterpriseWipe&searchBy=Serialnumber&id=$serial"
  echo "POST - $url"
  response=$(/usr/bin/curl -X POST $url -H "Authorization: $wsoClientID" -H "aw-tenant-code: $wsoSecret" -H  "accept: application/json" -H "Content-Type: application/json" -H "Content-Length: 0")
  #check if successful
  if [[ ! -z "$response" ]]; then
    #api failed
    echo "Failed - Reason: $response"
  fi
}

########## Perform Enterprise Wipe from Source WS1 via API ##########

removeWS1

########## Re-Enroll the Computer to new JSS server ##########
# Instructions: Uncomment one of the desired enrollment workflows and comment out the other two.
# Check if $enrollInvitationID has a value or is not equal to "optional"

#if [ -n "$enrollInvitationID" ] || [ "$enrollInvitationID" != "optional" ]; then

#  echo "Enrollment Invitation ID is set. Opening Enrollment Invitation URL."

# Option 1: Enrollment Invtation URL (Automatically sets destination Site as configured and skips Enrollment Admin authentication)
#  enrollmentURL="$NewjssURL/enroll?invitation=$enrollInvitationID"
#  open $enrollmentURL

#else

#  echo "Enrollment Invitation ID not set. Opening generic Enroll URL."

# Option 2: Generic Enrollment URL (requires Jamf Admin with Enroll Permissions or user is in IdP group allowed to Enroll)
  # Opens the Enrollment Invitation URL 
#  open $NewjssURL/enroll

#fi

# Option 3: Attempt to re-enroll using ADE (Requires correct MDM assignment in ABM/ASM)
sudo profiles renew -type enrollment

exit 0

