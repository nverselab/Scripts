#!/bin/bash

## Source: https://github.com/cliv/cs-falcon-protect-intune

# Configuration - Add this before uploading - It's a shame that Intune doesn't have secrets support... :(

CLIENT_ID="" # Required

CLIENT_SECRET="" # Required

CS_CCID="" # Required

CS_INSTALL_TOKEN="" # This is optional unless INTALL_TOKEN access is required by CrowdStrike

BASE_URL="https://api.crowdstrike.com" # Ex. https://api.crowdstrike.com, https://api.us-2.crowdstrike.com



if [[ $EUID -ne 0 ]]; then

    echo "This script must be run as root"

    exit 1

fi



get_access_token() {

    json=$(curl -s -X POST -d "client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}" ${BASE_URL}/oauth2/token)

    echo "function run() { let result = JSON.parse(\`$json\`); return result.access_token; }" | osascript -l JavaScript

}



get_sha256() {

    json=$(curl -s -H "Authorization: Bearer ${1}" ${BASE_URL}/sensors/combined/installers/v1\?filter=platform%3A%22mac%22)

    echo "function run() { let result = JSON.parse(\`$json\`); return result.resources[0].sha256; }" | osascript -l JavaScript

}



if [ ! -x "/Applications/Falcon.app/Contents/Resources/falconctl" ] || [ -z "$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep 'Sensor operational: true')" ]; then

    APITOKEN=$(get_access_token)

    FALCON_LATEST_SHA256=$(get_sha256 "${APITOKEN}")

    curl -o /tmp/FalconSensorMacOS.pkg -s -H "Authorization: Bearer ${APITOKEN}" ${BASE_URL}/sensors/entities/download-installer/v1?id=${FALCON_LATEST_SHA256}

    installer -verboseR -package /tmp/FalconSensorMacOS.pkg -target /

    rm /tmp/FalconSensorMacOS.pkg

    # Use this if INSTALL_TOKEN is NOT required
    /Applications/Falcon.app/Contents/Resources/falconctl license ${CS_CCID} || true # Don't fail if the app is already licensed, but still needs a reinstall

    # Use this if INSTALL_TOKEN is required
    # /Applications/Falcon.app/Contents/Resources/falconctl license ${CS_CCID} ${CS_INSTALL_TOKEN}
else

    echo "Crowdstrike Falcon is installed and operational"

fi