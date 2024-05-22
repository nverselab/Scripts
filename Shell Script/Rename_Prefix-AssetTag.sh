#!/bin/bash

# API client/secret variables (Requires Computers: Read permissions)

url="https://xxxxx.jamfcloud.com"
client_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
client_secret="xxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Rename Script Variables

prefix="$4"
suffix="$5"
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# API Token Functions

getAccessToken() {
	response=$(curl --silent --location --request POST "${url}/api/oauth/token" \
 	 	--header "Content-Type: application/x-www-form-urlencoded" \
 		--data-urlencode "client_id=${client_id}" \
 		--data-urlencode "grant_type=client_credentials" \
 		--data-urlencode "client_secret=${client_secret}")
 	access_token=$(echo "$response" | plutil -extract access_token raw -)
 	token_expires_in=$(echo "$response" | plutil -extract expires_in raw -)
 	token_expiration_epoch=$(($current_epoch + $token_expires_in - 1))
}

checkTokenExpiration() {
 	current_epoch=$(date +%s)
    if [[ token_expiration_epoch -ge current_epoch ]]
    then
        echo "Token valid until the following epoch time: " "$token_expiration_epoch"
    else
        echo "No valid token available, getting new token"
        getAccessToken
    fi
}

# Call API to get Asset Tag

checkTokenExpiration

inventory=$(curl -s --request GET -H "Accept: text/xml" -H "Authorization: Bearer $access_token" --url "$url/JSSResource/computers/serialnumber/$serial/subset/general")
assetTag=$(echo $inventory | /usr/bin/awk -F'<asset_tag>|</asset_tag>' '{print $2}' | tr [a-z] [A-Z])
echo "Asset Tag: $assetTag"

# Check if $assetTag is empty

if [ -z "$assetTag" ]; then
    echo "Asset Tag is empty, skipping host computer rename."
	exit 1

else
    # Rename host computer
	format="$prefix-$assetTag"

	echo "Setting Computer Name to $format"
    scutil --set HostName "$format"
    scutil --set LocalHostName "$format"
    scutil --set ComputerName "$format"
fi
