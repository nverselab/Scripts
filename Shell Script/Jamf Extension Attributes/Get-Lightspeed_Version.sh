#!/bin/bash

lightspeedversion=$(mobilefilter -v)

if [ -n "$lightspeedversion" ]; then
	echo "<result>$lightspeedversion</result>"
else
	echo "Not Installed"
fi
