#!/bin/sh

# Set the name prefix
prefix="$4"
suffix="$5"

# Get serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Get the logged-in user (excluding root and mbsetupuser)
logged_in_user=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Exit unsuccessfully if logged_in_user is root or _mbsetupuser
if [ "$logged_in_user" = "root" ] || [ "$logged_in_user" = "_mbsetupuser" ]; then
    echo "Error: Logged-in user is $logged_in_user, which is not desired. Exiting..."
    exit 1
fi

# Construct the hostname
hostname="$serial"
if [ -n "$prefix" ]; then
    hostname="$prefix-$hostname"
fi
if [ -n "$suffix" ]; then
    hostname="$hostname-$suffix"
elif [ -n "$logged_in_user" ]; then
    hostname="$hostname-$logged_in_user"
fi

# Set Hostname using the constructed hostname
echo "Setting computer name to $hostname locally..."
scutil --set HostName "$hostname"
scutil --set LocalHostName "$hostname"
scutil --set ComputerName "$hostname"

exit 0
