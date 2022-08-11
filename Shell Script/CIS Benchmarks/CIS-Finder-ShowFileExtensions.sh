#!/bin/sh
sudo -u $3 osascript <<eos
tell application "Finder"
    activate
    set all name extensions showing of Finder preferences to true
end tell
eos