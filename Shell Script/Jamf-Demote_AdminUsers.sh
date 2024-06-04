#!/bin/bash

# Define known local administrators to ignore ("Administrator" "jamfManage" "Helpdesk")
localadmins=("$4")

# Create a string with the names to ignore
ignore=$(IFS="|"; echo "${localadmins[*]}")

# Get list of regular users
users=$(dscl . -list /Users | egrep -v "_|root|nobody|daemon|$ignore")
echo "Found users: $users"

# Loop through them and remove them from Admins group if they are in it
for i in $users
do
    # Check if user is in admin group
    if dseditgroup -o checkmember -m $i admin > /dev/null; then
        # If user is in admin group, remove them from it
        dseditgroup -o edit -d $i -t user admin
    else
        # If user is not in admin group, skip them
        echo "User $i is not in admin group, skipping."
    fi
done
