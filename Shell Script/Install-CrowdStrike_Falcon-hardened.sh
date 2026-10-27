#!/bin/bash

# CrowdStrike Falcon for macOS deployment through Microsoft Intune
#
# Generate the obfuscated secret on a secured administrator Mac without putting
# the real secret in shell history:
#   read -r -s -p "CrowdStrike API client secret: " SECRET; echo
#   printf '%s' "$SECRET" | /usr/bin/base64 | /usr/bin/tr -d '\n'; echo
#   unset SECRET
# Paste only the resulting Base64 value into OBFUSCATED_CLIENT_SECRET.
#
# IMPORTANT: Base64 is obfuscation, not encryption. The real secret is not stored
# in clear text in this script, written to disk, printed, or placed in curl's
# command arguments. It must still be decoded briefly in process memory because
# the CrowdStrike OAuth endpoint requires the original client secret.

set -euo pipefail
set +x
umask 077

CLIENT_ID=""                       # Required
OBFUSCATED_CLIENT_SECRET=""        # Required: Base64 output generated above
CS_CCID=""                         # Required
CS_INSTALL_TOKEN=""                # Optional unless required by CrowdStrike
BASE_URL="https://api.crowdstrike.com"

FALCONCTL="/Applications/Falcon.app/Contents/Resources/falconctl"
PKG_PATH=""
APITOKEN=""
CLIENT_SECRET_DECODED=""

log() { /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() { /bin/echo "ERROR: $*" >&2; exit 1; }

cleanup() {
    if [[ -n "${PKG_PATH:-}" && -e "${PKG_PATH}" ]]; then
        /bin/rm -f "$PKG_PATH"
    fi
    unset APITOKEN CLIENT_SECRET_DECODED OBFUSCATED_CLIENT_SECRET CLIENT_ID
}
trap cleanup EXIT HUP INT TERM

require_value() {
    [[ -n "$2" ]] || fail "Required configuration value $1 is empty."
}

curl_config_escape() {
    /usr/bin/sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

get_access_token() {
    local escaped_id escaped_secret response token

    escaped_id="$(printf '%s' "$CLIENT_ID" | curl_config_escape)"
    CLIENT_SECRET_DECODED="$(printf '%s' "$OBFUSCATED_CLIENT_SECRET" | /usr/bin/base64 -D 2>/dev/null)" || \
        fail "OBFUSCATED_CLIENT_SECRET is not valid Base64."
    [[ -n "$CLIENT_SECRET_DECODED" ]] || fail "Decoded CrowdStrike API client secret is empty."
    escaped_secret="$(printf '%s' "$CLIENT_SECRET_DECODED" | curl_config_escape)"
    unset CLIENT_SECRET_DECODED

    response="$({
        printf 'request = "POST"\n'
        printf 'header = "Content-Type: application/x-www-form-urlencoded"\n'
        printf 'data-urlencode = "client_id=%s"\n' "$escaped_id"
        printf 'data-urlencode = "client_secret=%s"\n' "$escaped_secret"
        printf 'silent\nshow-error\nfail\n'
    } | /usr/bin/curl --config - "${BASE_URL}/oauth2/token")" || \
        fail "CrowdStrike OAuth token request failed."

    unset escaped_id escaped_secret
    token="$(printf '%s' "$response" | /usr/bin/plutil -extract access_token raw -o - - 2>/dev/null)" || \
        fail "CrowdStrike OAuth response did not contain an access token."
    unset response
    [[ -n "$token" ]] || fail "CrowdStrike returned an empty access token."
    printf '%s' "$token"
}

get_latest_installer_sha256() {
    local token="$1" escaped_token response sha256
    escaped_token="$(printf '%s' "$token" | curl_config_escape)"
    response="$({
        printf 'header = "Authorization: Bearer %s"\n' "$escaped_token"
        printf 'silent\nshow-error\nfail\n'
    } | /usr/bin/curl --config - \
        "${BASE_URL}/sensors/combined/installers/v1?filter=platform%3A%22mac%22")" || \
        fail "Unable to query the current CrowdStrike macOS installer."
    unset escaped_token token

    sha256="$(printf '%s' "$response" | /usr/bin/plutil -extract resources.0.sha256 raw -o - - 2>/dev/null)" || \
        fail "CrowdStrike installer response did not contain a SHA-256 identifier."
    unset response
    [[ -n "$sha256" ]] || fail "CrowdStrike returned an empty installer SHA-256 identifier."
    printf '%s' "$sha256"
}

download_installer() {
    local token="$1" sha256="$2" destination="$3" escaped_token
    escaped_token="$(printf '%s' "$token" | curl_config_escape)"
    {
        printf 'header = "Authorization: Bearer %s"\n' "$escaped_token"
        printf 'silent\nshow-error\nfail\nlocation\n'
    } | /usr/bin/curl --config - --output "$destination" \
        "${BASE_URL}/sensors/entities/download-installer/v1?id=${sha256}" || \
        fail "Unable to download the CrowdStrike Falcon installer."
    unset escaped_token token
    [[ -s "$destination" ]] || fail "Downloaded CrowdStrike installer is empty."
}

[[ "$EUID" -eq 0 ]] || fail "This script must run as root."
require_value "CLIENT_ID" "$CLIENT_ID"
require_value "OBFUSCATED_CLIENT_SECRET" "$OBFUSCATED_CLIENT_SECRET"
require_value "CS_CCID" "$CS_CCID"

if [[ -x "$FALCONCTL" ]] && "$FALCONCTL" stats 2>/dev/null | /usr/bin/grep -q 'Sensor operational: true'; then
    log "CrowdStrike Falcon is installed and operational. No action is required."
    exit 0
fi

log "CrowdStrike Falcon is not installed or is not operational. Starting remediation."
APITOKEN="$(get_access_token)"
FALCON_LATEST_SHA256="$(get_latest_installer_sha256 "$APITOKEN")"
PKG_PATH="$(/usr/bin/mktemp /private/tmp/FalconSensorMacOS.XXXXXX.pkg)"
/bin/chmod 600 "$PKG_PATH"

download_installer "$APITOKEN" "$FALCON_LATEST_SHA256" "$PKG_PATH"
unset APITOKEN

log "Installing CrowdStrike Falcon."
/usr/sbin/installer -pkg "$PKG_PATH" -target / >/dev/null
[[ -x "$FALCONCTL" ]] || fail "Installation completed, but falconctl was not found."

if [[ -n "$CS_INSTALL_TOKEN" ]]; then
    "$FALCONCTL" license "$CS_CCID" "$CS_INSTALL_TOKEN" >/dev/null 2>&1 || true
else
    "$FALCONCTL" license "$CS_CCID" >/dev/null 2>&1 || true
fi

log "CrowdStrike Falcon installation and licensing commands completed."
exit 0
