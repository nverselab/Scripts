#!/bin/bash

# Path to the log file
log_file="/Library/Management/super/logs/msu-workflow.log"

# Get the current macOS version
current_os_version=$(sw_vers -productVersion)

# Check if the last line contains the specified string
if tail -n 1 "$log_file" | grep -q "DOWNLOAD MACOS VIA SOFTWAREUPDATE COMPLETED"; then
    # If found, echo the most recent line that has "Downloaded:"
    last_downloaded=$(grep "Downloaded:" "$log_file" | tail -n 1)
    if [[ -n "$last_downloaded" && "$last_downloaded" == *"$current_os_version"* ]]; then
        echo "<result>Upgrade Complete</result>"
    elif [ -n "$last_downloaded" ]; then
        echo "<result>$last_downloaded</result>"
    else
        echo "<result>No downloads staged.</result>"
    fi
else
# If not found, echo the most recent line that has "Downloading:" with the highest percentage
    last_downloading=$(grep -E "Downloading:.*%" "$log_file" | tail -c 20)
    if [ -n "$last_downloading" ]; then
        echo "<result>$last_downloading</result>"
    else
        echo "<result>No downloads staged.</result>"
    fi
fi
