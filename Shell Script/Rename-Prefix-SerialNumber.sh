#!/bin/sh

# Set the name prefix
prefix="Prefix"

# Get serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Set Hostname using variable created above
echo "Setting computer name to $serial locally..."
scutil --set HostName "$prefix-$serial"
scutil --set LocalHostName "$prefix-$serial"
scutil --set ComputerName "$prefix-$serial"


exit 0