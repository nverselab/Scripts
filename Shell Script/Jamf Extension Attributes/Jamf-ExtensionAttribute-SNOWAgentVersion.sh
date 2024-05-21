#!/bin/bash

# Path to the SNOW Agent
agentPath="/opt/snow/snowagent"

# Check if the agent exists
if [ -f "$agentPath" ]; then
    agentVersion=$($agentPath version)
    echo "<result>$agentVersion</result>"
else
    # If it doesn't exist, echo "Not Installed"
    echo "<result>Not Installed</result>"
fi
