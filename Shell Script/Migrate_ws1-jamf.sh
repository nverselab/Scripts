#!/bin/bash

# Note: this is a work in progress and may not be ready for production.

originurl="required" # The WS1 API URL of source environment (example: https://xx####.awmdm.com)
oAuthTokenURL="https://na.uemauth.vmwservices.com/connect/token" # The Access Token URL for your VMWare WS1 Tenant (differs by region: https://kb.omnissa.com/s/article/76967)
wsoClientID="required" # REST API oAuth client ID for the source WS1 tenant. Requires Console Administrator role or similar to use the API
wsoSecret="required" # API oAuth credentials for the client ID in the source WS1 tenant
NewjssURL="optional" # The URL of the new JSS server (e.g. https://yourSubDomain.jamfcloud.com)
enrollInvitationID="optional"
serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`

# Get the logged in user's name
LoggedinUser=$(/usr/bin/stat -f%Su /dev/console)

# Check to see if a user is logged in and exit unsuccessfully if they are not

if [ -z "$LoggedinUser" -o "$LoggedinUser" = "loginwindow" ]; then
    echo "no user logged in, cannot proceed"
    exit 1
fi

# Obtain an authorization token
auth_response=$(curl -X POST "$oAuthTokenURL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$wsoClientID&client_secret=$wsoSecret")

# Extract the bearer token from the response using sed
bearertoken=$(echo $auth_response | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

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
  response=$(/usr/bin/curl -X POST $url -H "Authorization: Bearer $bearertoken" -H "accept: application/json" -H "Content-Type: application/json" -H "Content-Length: 0")
  #check if successful
  if [[ ! -z "$response" ]]; then
    #api failed
    echo "Failed - Reason: $response"
  fi
}

########## Perform Enterprise Wipe from Source WS1 via API ##########

# Check if credentials are set
if [[ "$wsoClientID" == "required" && "$wsoSecret" == "required" && "$originurl" == "required" ]]; then
  echo "Error: API credentials or origin URL are not set. Please set wsoClientID, wsoSecret, and originurl variables."
  exit 1
fi

removeWS1

echo "Waiting for all WSO profiles to be removed..."

# Loop until no profiles assumed from WSO are found or until 30 minutes have passed
timeout=1800  # 30 minutes in seconds
interval=10   # Check every 10 seconds
elapsed=0

while profiles -P | grep -iqE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'; do
  if [ $elapsed -ge $timeout ]; then
    echo "Timeout reached. WSO profiles were not removed within 30 minutes."
    exit 1
  fi
  echo "WSO profiles still present. Checking again in 10 seconds..."
  sleep $interval
  elapsed=$((elapsed + interval))
done

echo "All WSO profiles have been removed."

########## Re-Enroll the Computer to new JSS server ##########
# Instructions: Uncomment one of the desired enrollment workflows and comment out the other two.
# Check if $enrollInvitationID has a value or is not equal to "optional"

if [ -n "$enrollInvitationID" ] && [ "$enrollInvitationID" != "optional" ]; then

  echo "Enrollment Invitation ID is set. Opening Enrollment Invitation URL."

# Option 1: Enrollment Invtation URL (Automatically sets destination Site as configured and skips Enrollment Admin authentication)
  enrollmentURL="$NewjssURL/enroll?invitation=$enrollInvitationID"
  open $enrollmentURL

else

  echo "Enrollment Invitation ID not set. Opening generic Enroll URL."

# Option 2: Generic Enrollment URL (requires Jamf Admin with Enroll Permissions or user is in IdP group allowed to Enroll)

  if [ -n "$NewjssURL" ] && [ "$NewjssURL" != "optional" ]; then
    # Opens the Enrollment Invitation URL 
    open $NewjssURL/enroll

  else

    echo "New JSS URL not set. Attempting Automated Device Enrollment with Apple Business/School Manager."
    
  fi

fi

# Option 3: Attempt to re-enroll using ADE (Requires correct MDM assignment in ABM/ASM)

## Elevate user if not an administrator

# Prompt for Password until entered
userPass=""
until [[ $userPass != "" ]]
do
userPass=$(/usr/bin/osascript<<END
application "System Events"
activate
set the answer to text returned of (display dialog "IT needs to set some things up for you complete re-enrollment.  Please Enter your Password:" default answer "" with hidden answer buttons {"Continue"} default button 1)
END
)
done
    
# Loop until successful
result=""

until [[ $result == "success" ]]
do
    
## Temorarily Elevate User if they aren't already an Admin
    
if groups $LoggedinUser | grep -q -w admin; then 
    admin="yes"
else 
    /usr/sbin/dseditgroup -o edit -a $LoggedinUser -t user admin
fi

sudo profiles renew -type enrollment
sleep 320

## Remove User from Admin if they were not already an admin
# Note: Needs testing. May need to add a delay for MDM Profile install time.

if [[ $admin != "yes" ]]; then
dseditgroup -o edit -d $LoggedinUser -t user admin
fi

exit 0
