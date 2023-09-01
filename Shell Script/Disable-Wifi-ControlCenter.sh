#!/bin/bash

# Hide Wifi from Control Center (Must run Per User)

currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

sudo -u $currentUser defaults -currentHost write com.apple.controlcenter WiFi -int 8

# Optional Disable Wifi Completely (System Setting)

# networksetup -setairportpower en0 off

# networksetup -setnetworkserviceenabled Wi-Fi off

killall ControlCenter
