#!/bin/bash

# Get the current logged in user
loggedInUser=$(stat -f%Su /dev/console)

# Change the ownership of /Applications/8x8 Work.app to the logged in user
sudo chown -R "$loggedInUser" "/Applications/8x8 Work.app"

# Change the ownership of ~/Library/Caches/com.electron.8x8---virtual-office.ShipIt to the logged in user
sudo chown -R "$loggedInUser" "/Users/$loggedInUser/Library/Caches/com.electron.8x8---virtual-office.ShipIt"
