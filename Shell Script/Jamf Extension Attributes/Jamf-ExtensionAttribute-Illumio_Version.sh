#!/bin/bash
					
illumioVersion=$(sudo /opt/illumio_ven/illumio-ven-ctl version)
					
if [[ -n $illumioVersion ]]; then
	echo "<result>$illumioVersion</result>"
else 
	echo "<result>Not Installed</result>"
fi
