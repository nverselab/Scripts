#!/bin/sh
# Check to see if Nessus Agent is installed
NessusAgentInstalled="$(ls /Library/NessusAgent/run/sbin/ | grep nessuscli)"
if [ "$NessusAgentInstalled" != "nessuscli" ] 
then
 echo "<result>Not Installed</result>"
else 
 NessusAgentVersion="$(/Library/NessusAgent/run/sbin/nessuscli -v | awk 'NR==1{print $4}')"
 echo "<result>$NessusAgentVersion</result>"
fi
