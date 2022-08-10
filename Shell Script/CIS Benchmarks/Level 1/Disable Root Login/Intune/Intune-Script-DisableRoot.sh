#!/bin/bash
rootCheck=`dscl . read /Users/root | grep AuthenticationAuthority 2>&1 > /dev/null ; echo $?`
if [ "${rootCheck}" == 1 ]; then
	echo "Disabled"
        exit 0
else
	echo "Enabled"

        # remove the AuthenticationAuthority from the user's account
        dscl . delete /Users/root AuthenticationAuthority

        # Put a single asterisk in the password entry, thus locking the account.
        dscl . -create /Users/root Password '*'

        # Disable root login by setting root's shell to /usr/bin/false
        ## This will prevent use of 'su root' or 'su -' to elevate to root.
        ## Comment out, remove, or use 'sudo' with another admin account if needed.
        dscl . -create /Users/root UserShell /usr/bin/false

       # Let's validate and report back to Intune the post-script results.
       if [ "${rootCheck}" == 1 ]; then
            echo "Root was Enabled and is now Disabled"
            exit 0
       else
	    echo "Failure: Root was Enabled and is still Enabled"
            exit 1
       fi
fi