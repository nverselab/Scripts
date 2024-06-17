#!/bin/bash

# Path to the log file
log_file="/Library/Management/super/logs/msu-workflow.log"

# Check if the last line contains the specified string
if tail -n 1 "$log_file" | grep -q "DOWNLOAD MACOS VIA SOFTWAREUPDATE COMPLETED"; then
    # If found, echo the most recent line that has "Downloaded:"
    last_downloaded=$(grep "Downloaded:" "$log_file" | tail -n 1)
    if [ -n "$last_downloaded" ]; then
        echo "$last_downloaded"
    else
        echo "No downloads staged."
    fi
else
    # If not found, echo the most recent line that has "Downloading:"
    last_downloading=$(grep "Downloading:" "$log_file" | tail -n 1)
    if [ -n "$last_downloading" ]; then
        echo "$last_downloading"
    else
        echo "No downloads staged."
    fi
fi
