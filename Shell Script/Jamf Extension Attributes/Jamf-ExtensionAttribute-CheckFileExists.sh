#!/bin/bash
FILE="/Library/ArcticWolfNetworks/Agent/uninstall.sh"

if [ ! -f $FILE ]; then
    echo "<result>Not Installed</result>"
else
    echo "<result>Installed</result>"
fi