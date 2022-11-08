#!/bin/bash
FILE="/Library/ArcticWolfNetworks/Agent/uninstall.sh"

# if the file doesn't exist, try to create folder
if [ ! -f $FILE ]
then
    echo "<result>Not Installed</result>"
else
    echo "<result>Installed</result>"
fi