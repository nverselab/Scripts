#!/bin/bash

# Get the list of all users excluding 'nobody' and 'root'
users=$(dscl . list /Users | grep -v '^_' | grep -v 'nobody' | grep -v 'root')

# Loop through each user
for user in $users; do
  userHome=$(dscl . -read /Users/$user NFSHomeDirectory | awk '{print $2}')
  echo "Checking $user in $userHome"
  
  # Check if the directory exists, if not, create it
  if [ ! -d "$userHome/Library/Application Support/Google" ]; then
    mkdir -p "$userHome/Library/Application Support/Google"
  fi

  # Change ownership of the Google directory
  sudo chown -R "$user:staff" "$userHome/Library/Application Support/Google"
  sudo chmod -R 755 "$userHome/Library/Application Support/Google"
done
