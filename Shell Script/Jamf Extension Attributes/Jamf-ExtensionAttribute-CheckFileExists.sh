#!/bin/bash

##### Use the below for a file

FILE="/Library/ArcticWolfNetworks/Agent/uninstall.sh"

if [ ! -f $FILE ]; then
    echo "<result>Not Installed</result>"
else
    echo "<result>Installed</result>"
fi

##### Use the below for a folder instead of a file

#!/bin/bash
FOLDER="/Library/ArcticWolfNetworks/Agent"

if [ ! -d "$FOLDER" ]; then
    echo "<result>Not Installed</result>"
else
    echo "<result>Installed</result>"
fi
