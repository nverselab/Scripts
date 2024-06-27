#!/bin/bash

# Run the nessuscli command with sudo and extract the epoch time from the "Last scanned:" line
epochTime=$(sudo /Library/NessusAgent/run/sbin/nessuscli agent status | grep '^Last scanned:' | awk '{print $3}')

# Check if epochTime is not empty
if [ -n "$epochTime" ]; then
    # Convert the epoch time to the specified format
    formattedDate=$(date -r "$epochTime" '+%Y-%m-%d %H:%M:%S')

    # Echo the result within <result> and </result> tags
    echo "<result>$formattedDate</result>"
else
    echo "<result>Error: 'Last scanned' time not found.</result>"
fi
