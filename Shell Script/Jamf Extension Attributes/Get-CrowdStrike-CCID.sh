#!/bin/sh

# Reports back the customerID: result from the agent_info section of a falconctl stats query

result="Not Installed or Running"

if [ -e /Applications/Falcon.app/Contents/MacOS/Falcon ]; then
	syextNum=$(systemextensionsctl list | awk '/com.crowdstrike.falcon.Agent/ {print $7,$8}' | wc -l) 
	if [ $syextNum -gt 0 ]; then
		result=$(/Applications/Falcon.app/Contents/Resources/falconctl stats | awk '/customerID:/ {print $2}')
	fi
fi

echo "<result>$result</result>"
