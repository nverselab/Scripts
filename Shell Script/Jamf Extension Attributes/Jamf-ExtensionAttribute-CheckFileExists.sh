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

##### Use the following to extract the Version Number of a file

FILE="/Library/ArcticWolfNetworks/Agent/uninstall.sh"

if [ -f "$FILE" ]; then
    # Use mdls to get the version number
    VERSION=$(mdls -name kMDItemVersion -raw "$FILE")

    if [ -n "$VERSION" ]; then
        echo "<result>$VERSION</result>"
    else
        echo "<result>Installed, Version information not available</result>"
    fi
else
    echo "<result>Not Installed</result>"
fi
