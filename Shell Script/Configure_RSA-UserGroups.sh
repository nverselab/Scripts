#!/bin/bash

# Group names
adminGroup="Administrators"
userGroup="Users"

# Array of admins to add to the Administrators group
admins=("Administrator" "admin2" "admin3")

# SecureID MFA Agent Control Center App Path
rsaApp="/Applications/SecureID\ MFA\ Agent\ Control\ Center.app"

# Check for and create Administrators group if necessary
if ! dscl . -read /Groups/$adminGroup; then
    sudo dseditgroup -o create -q $adminGroup
fi

# Check for and create Users group if necessary
if ! dscl . -read /Groups/$userGroup; then
    sudo dseditgroup -o create -q $userGroup
fi

# Add admins to Administrators group if they're not already in it
for admin in "${admins[@]}"; do
    if ! dseditgroup -o checkmember -m "$admin" $adminGroup; then
        sudo dseditgroup -o edit -a "$admin" -t user $adminGroup
    fi
done

# Get the current logged in user
loggedInUser=$(stat -f%Su /dev/console)

# Add the logged in user to Users group if they're not already in it
if ! dseditgroup -o checkmember -m "$loggedInUser" $userGroup; then
    sudo dseditgroup -o edit -a "$loggedInUser" -t user $userGroup
fi

# Open the SecureID Control Center app so the user can test their RSA token
open $rsaApp
