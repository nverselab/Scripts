#!/bin/bash

arch=$(/usr/bin/arch)

if [ "$arch" == "arm64" ]; then
    echo "Apple Silicon Detected"
    chmod +x $5/agent_installer-arm64.sh
    /bin/sh $5/agent_installer-arm64.sh install_start --token $4
else
    echo "Intel Detected"
    chmod +x $5/agent_installer.sh
    /bin/sh $5/agent_installer.sh install_start --token $4
fi

# Detect Rapid7 is running

if pgrep -x "ir_agent" >/dev/null; then
    echo "Install Successful"
    # Clean Up
    rm -rf /private/tmp/rapid7
    exit 0
else
    echo "Install Failed"
    # Clean Up
    rm -rf /private/tmp/rapid7
    exit 1
fi
