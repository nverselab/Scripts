#!/bin/sh

# Set the name prefix
prefix="$4"
suffix="$5"

# Get serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Construct the hostname
hostname="$serial"
if [ -n "$prefix" ]; then
    hostname="$prefix-$hostname"
fi
if [ -n "$suffix" ]; then
    hostname="$hostname-$suffix"
fi

# Set Hostname using the constructed hostname
echo "Setting computer name to $hostname locally..."
scutil --set HostName "$hostname"
scutil --set LocalHostName "$hostname"
scutil --set ComputerName "$hostname"

exit 0
