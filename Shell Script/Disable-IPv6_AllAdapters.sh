#!/bin/bash

# Get list of all network services
services=$(networksetup -listallnetworkservices | tail -n +2)

# Loop through them and disable IPv6 if it is enabled
for service in $services
do
    # Check if IPv6 is enabled for the service
    if networksetup -getinfo "$service" | grep -q "IPv6: Automatic"; then
        # If IPv6 is enabled, disable it
        networksetup -setv6off "$service"
        echo "IPv6 has been disabled for $service."
    else
        # If IPv6 is not enabled, skip to the next service
        echo "IPv6 is not enabled for $service, skipping."
    fi
done
