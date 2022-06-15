#!/bin/bash
rootCheck=`dscl . read /Users/root | grep AuthenticationAuthority 2>&1 > /dev/null ; echo $?`
if [ "${rootCheck}" == 1 ]; then
	echo "Disabled"
else
	echo "Enabled"
fi