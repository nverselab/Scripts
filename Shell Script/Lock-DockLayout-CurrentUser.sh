#!/bin/bash

currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# Convenience function to run a command as the current user
# Usage: runAsUser command arguments...
runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
    exit 1
  fi
}

# Prevent changes to the Dock for logged-in user.  Set to False to unlock.

runAsUser defaults write com.apple.Dock contents-immutable -bool true; killall Dock

exit 0