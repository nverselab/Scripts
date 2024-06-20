#!/bin/bash

# Check if /opt/snow/snowagent exists
if [ -f "/opt/snow/snowagent" ]; then
    # Run the command and capture the output
    version=$(sudo /opt/snow/snowagent version | cut -d '+' -f1)
    # Echo the result within XML tags
    echo "<result>$version</result>"
else
    # Echo "Not Installed" if the file does not exist
    echo "<result>Not Installed</result>"
fi
