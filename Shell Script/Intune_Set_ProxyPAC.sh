#!/bin/bash
# HARDCODED VALUES ARE SET HERE
autoProxyURL="yourProxyPacURL"
 
log() {
    printf '%s %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    log "ERROR: This script must run as root."
    exit 1
fi
 
# Detects all network hardware & creates services for all installed network hardware
if ! /usr/sbin/networksetup -detectnewhardware; then
    log "ERROR: Could not detect new network hardware."
    exit 1
fi
 
services=$(/usr/sbin/networksetup -listallnetworkservices) || {
    log "ERROR: Could not list network services."
    exit 1
}
services=${services#*$'\n'}
failureCount=0
matchedCount=0
 
while IFS= read -r i; do

    # Match the network services this script manages.
    case "$i" in
        *Ethernet*|*Linksys\ USB3GIGV1*|*USB\ 10/100/1000\ LAN*|*Wi-Fi*)
        matchedCount=$((matchedCount + 1))
        proxyInfo=$(/usr/sbin/networksetup -getautoproxyurl "$i") || {
            log "ERROR: Could not read the proxy setting for service: $i"
            failureCount=$((failureCount + 1))
            continue
        }
        autoProxyURLLocal=${proxyInfo%%$'\n'*}
        autoProxyURLLocal=${autoProxyURLLocal#URL: }

        log "$i proxy set to $autoProxyURLLocal"

        if [[ "$autoProxyURLLocal" != "$autoProxyURL" ]]; then
            if /usr/sbin/networksetup -setautoproxyurl "$i" "$autoProxyURL"; then
                verifiedProxyInfo=$(/usr/sbin/networksetup -getautoproxyurl "$i") || {
                    log "ERROR: Could not verify the proxy for service: $i"
                    failureCount=$((failureCount + 1))
                    continue
                }
                verifiedProxyURL=${verifiedProxyInfo%%$'\n'*}
                verifiedProxyURL=${verifiedProxyURL#URL: }
                if [[ "$verifiedProxyURL" == "$autoProxyURL" ]]; then
                    log "Set and verified proxy for $i"
                else
                    log "ERROR: Proxy verification failed for service: $i"
                    failureCount=$((failureCount + 1))
                fi
            else
                log "ERROR: Could not set the proxy for service: $i"
                failureCount=$((failureCount + 1))
            fi
        fi
        ;;
    esac
done <<< "$services"

if [[ $matchedCount -eq 0 ]]; then
    log "No matching network services found."
    exit 0
fi

if [[ $failureCount -gt 0 ]]; then
    log "ERROR: Failed to configure $failureCount network service(s)."
    exit 1
fi

log "Proxies All Present And Correct..."
