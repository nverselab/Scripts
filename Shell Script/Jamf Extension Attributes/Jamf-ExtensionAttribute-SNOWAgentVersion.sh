#!/bin/bash

# Path to the SNOW Agent
agentPath="/opt/snow/snowagent"

# Check if the agent exists
if [ -f "$agentPath" ]; then
    # If it exists, get the version and store it in a variable
    agentVersion=$($agentPath version)
    # Truncate the version to only show characters before the '+'
    truncatedVersion=$(echo $agentVersion | awk -F'+' '{print $1}')
    # Echo the truncated version
    echo "<result>$truncatedVersion</result>"
else
    # If it doesn't exist, echo "Not Installed"
    echo "<result>Not Installed</result>"
fi
