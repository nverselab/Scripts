#!/bin/bash

# Jamf parameters:
#   $4: comma-separated usernames to protect (for example: jamfadmin,localadmin)
#   $5: DRY_RUN (default), DELETE, or SIMULATE
#   $6: inactivity threshold in days (default: 30)

set -u
export LC_ALL=C

readonly DAYS_INACTIVE="${6:-30}"
readonly SECONDS_PER_DAY=86400
readonly PROTECTED_USERS="${4:-}"
readonly ACTION="${5:-DRY_RUN}"

log() {
    /bin/echo "prune_stale_admins: $*"
}

if [[ ! "$DAYS_INACTIVE" =~ ^[0-9]+$ ]] || (( 10#$DAYS_INACTIVE <= 0 )); then
    log "ERROR: Jamf parameter 6 must be a positive whole number of days."
    exit 1
fi

if [[ "$(/usr/bin/id -u)" -ne 0 ]]; then
    log "ERROR: Must run as root. No changes made."
    exit 1
fi

now=$(/bin/date +%s) || {
    log "ERROR: Could not determine current time. No changes made."
    exit 1
}
cutoff=$((now - DAYS_INACTIVE * SECONDS_PER_DAY))
current_user=$(/usr/bin/stat -f '%Su' /dev/console 2>/dev/null || true)

is_protected_user() {
    local candidate="$1"
    local entry
    local -a entries

    [[ "$candidate" == "root" || "$candidate" == "$current_user" ]] && return 0

    IFS=',' read -r -a entries <<< "$PROTECTED_USERS"
    for entry in "${entries[@]}"; do
        entry=$(/usr/bin/printf '%s' "$entry" | /usr/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [[ -n "$entry" && "$candidate" == "$entry" ]] && return 0
    done
    return 1
}

is_logged_in() {
    local candidate="$1"
    /usr/bin/who | /usr/bin/awk -v user="$candidate" '$1 == user { found = 1 } END { exit !found }'
}

last_login_epoch() {
    local candidate="$1"
    local record
    local month day time year parsed
    local current_year

    # `last` is the available local login-accounting history; if it has no usable
    # entry, the caller skips this account rather than treating it as inactive.
    record=$(/usr/bin/last -1 "$candidate" 2>/dev/null | /usr/bin/awk -v user="$candidate" '
        BEGIN { split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", months, " ");
                for (i = 1; i <= 12; i++) month[months[i]] = 1 }
        {
            if ($1 != user) next
            for (i = 1; i <= NF; i++) {
                if ($i in month && i + 2 <= NF) {
                    print $i, $(i + 1), $(i + 2), $(i + 3)
                    exit
                }
            }
        }')
    [[ -n "$record" ]] || return 1

    read -r month day time year <<< "$record"
    if [[ "$year" =~ ^[0-9]{4}$ ]]; then
        parsed=$(/bin/date -j -f '%b %e %T %Y' "$month $day $time $year" +%s 2>/dev/null) || return 1
    else
        current_year=$(/bin/date +%Y) || return 1
        parsed=$(/bin/date -j -f '%b %e %T %Y' "$month $day $time $current_year" +%s 2>/dev/null) || return 1
        # Some `last` output omits the year. If that timestamp would be in the
        # future, it belongs to the previous calendar year.
        if (( parsed > now )); then
            parsed=$(/bin/date -j -f '%b %e %T %Y' "$month $day $time $((current_year - 1))" +%s 2>/dev/null) || return 1
        fi
    fi

    /usr/bin/printf '%s\n' "$parsed"
}

get_home_directory() {
    local candidate="$1"
    /usr/bin/dscl . -read "/Users/$candidate" NFSHomeDirectory 2>/dev/null |
        /usr/bin/sed -n 's/^NFSHomeDirectory: //p'
}

delete_account() {
    local candidate="$1"
    local home="$2"
    local home_name

    home_name="${home#/Users/}"
    if [[ "$home" != /Users/* || "$home_name" == "$home" || "$home_name" == */* ||
          "$home_name" == "." || "$home_name" == ".." ||
          "$home" == "/Users/Shared" || -L "$home" ]]; then
        log "Skipping '$candidate': unsafe or unmanaged home path '$home'."
        return 1
    fi

    if [[ "$ACTION" != "DELETE" && "$ACTION" != "SIMULATE" ]]; then
        log "DRY RUN: Would delete stale administrator '$candidate' and home '$home'."
        return 0
    fi

    log "Deleting stale administrator '$candidate'."
    if ! /usr/sbin/sysadminctl -deleteUser "$candidate"; then
        log "ERROR: Account deletion failed for '$candidate'; home directory retained."
        return 1
    fi

    if /usr/bin/dscl . -read "/Users/$candidate" >/dev/null 2>&1; then
        log "ERROR: '$candidate' still exists after deletion attempt; home directory retained."
        return 1
    fi

    if [[ -d "$home" ]]; then
        if ! /bin/rm -rf "$home"; then
            log "ERROR: Could not remove home directory '$home'."
            return 1
        fi
        log "Removed home directory '$home'."
    else
        log "No home directory exists at '$home'."
    fi
}

simulate_cleanup() {
    local candidate="$1"
    local home="$2"

    if /usr/bin/dscl . -read "/Users/$candidate" >/dev/null 2>&1; then
        if ! /usr/sbin/sysadminctl -deleteUser "$candidate" >/dev/null 2>&1; then
            log "ERROR: Cleanup could not delete simulation account '$candidate'."
        fi
    fi
    if ! /usr/bin/dscl . -read "/Users/$candidate" >/dev/null 2>&1 &&
       [[ "$home" == "/Users/$candidate" && -d "$home" && ! -L "$home" ]]; then
        if ! /bin/rm -rf "$home"; then
            log "ERROR: Cleanup could not remove simulation home '$home'."
            return 1
        fi
    fi
    if /usr/bin/dscl . -read "/Users/$candidate" >/dev/null 2>&1; then
        log "ERROR: Simulation account '$candidate' remains after cleanup attempt."
        return 1
    fi
}

run_simulation() {
    local candidate="jamfsim_$(/bin/date +%s)_$$"
    local password
    local home="/Users/$candidate"
    local simulated_last_login
    local uid
    local groups

    if /usr/bin/dscl . -read "/Users/$candidate" >/dev/null 2>&1; then
        log "ERROR: Simulation account '$candidate' already exists."
        return 1
    fi

    password=$(/usr/bin/openssl rand -hex 24) || {
        log "ERROR: Could not generate a temporary password."
        return 1
    }

    log "Creating temporary administrator '$candidate' for the simulation."
    if ! /usr/sbin/sysadminctl -addUser "$candidate" \
        -fullName "Jamf Cleanup Simulation" \
        -password "$password" -admin -home "$home"; then
        log "ERROR: Could not create simulation account."
        simulate_cleanup "$candidate" "$home"
        return 1
    fi
    unset password

    uid=$(/usr/bin/dscl . -read "/Users/$candidate" UniqueID 2>/dev/null |
        /usr/bin/awk '{ print $2 }')
    groups=$(/usr/bin/id -Gn "$candidate" 2>/dev/null) || groups=""
    if [[ ! "$uid" =~ ^[0-9]+$ ]] || (( uid < 500 )) ||
       ! /usr/bin/printf '%s\n' "$groups" | /usr/bin/tr ' ' '\n' | /usr/bin/grep -Fxq admin; then
        log "ERROR: Simulation account did not validate as a standard administrator."
        simulate_cleanup "$candidate" "$home"
        return 1
    fi

    home=$(get_home_directory "$candidate")
    if [[ "$home" != "/Users/$candidate" || -L "$home" ]]; then
        log "ERROR: Simulation account has an unexpected home directory path '$home'."
        simulate_cleanup "$candidate" "/Users/$candidate"
        return 1
    fi

    if [[ ! -d "$home" ]]; then
        log "Creating the test account's home directory."
        if ! /usr/sbin/createhomedir -c -u "$candidate" >/dev/null 2>&1 || [[ ! -d "$home" ]]; then
            log "ERROR: Could not create simulation home directory '$home'."
            simulate_cleanup "$candidate" "$home"
            return 1
        fi
    fi

    # macOS login accounting has no supported interface for safely fabricating
    # a `last` record. Supply a test timestamp 35 days ago to the same age check.
    simulated_last_login=$((now - (DAYS_INACTIVE + 5) * SECONDS_PER_DAY))
    if (( simulated_last_login > cutoff )); then
        log "ERROR: Simulated timestamp did not meet the inactivity threshold."
        simulate_cleanup "$candidate" "$home"
        return 1
    fi

    log "Simulating a last login $((DAYS_INACTIVE + 5)) days ago and verifying the deletion path."
    if ! delete_account "$candidate" "$home"; then
        log "ERROR: Simulation deletion failed; attempting cleanup of '$candidate'."
        simulate_cleanup "$candidate" "$home"
        return 1
    fi

    if /usr/bin/dscl . -read "/Users/$candidate" >/dev/null 2>&1 || [[ -e "$home" ]]; then
        log "ERROR: Simulation failed verification; account or home still exists."
        simulate_cleanup "$candidate" "$home"
        return 1
    fi

    log "Simulation passed: temporary account and home directory were removed."
}

case "$ACTION" in
    DRY_RUN|DELETE|SIMULATE) ;;
    *)
        log "ERROR: Unsupported action '$ACTION'. Use DRY_RUN, DELETE, or SIMULATE."
        exit 1
        ;;
esac

if [[ "$ACTION" == "SIMULATE" ]]; then
    run_simulation
    exit $?
fi

if [[ "$ACTION" == "DRY_RUN" ]]; then
    log "DRY RUN mode. Set Jamf parameter 5 to DELETE to enable account and home removal."
fi

users=$(/usr/bin/dscl . -list /Users UniqueID 2>/dev/null) || {
    log "ERROR: Could not enumerate local accounts."
    exit 1
}

while read -r username uid; do
    [[ -n "${username:-}" && "${uid:-}" =~ ^[0-9]+$ ]] || continue

    # Standard macOS system accounts have UIDs below 500.
    (( uid >= 500 )) || continue
    [[ "$username" != _* ]] || continue
    [[ "$username" =~ ^[a-zA-Z0-9._-]+$ ]] || {
        log "Skipping account with an unsupported username: '$username'."
        continue
    }

    is_protected_user "$username" && continue
    is_logged_in "$username" && {
        log "Skipping logged-in account '$username'."
        continue
    }

    groups=$(/usr/bin/id -Gn "$username" 2>/dev/null) || {
        log "Skipping '$username': could not determine group membership."
        continue
    }
    /usr/bin/printf '%s\n' "$groups" | /usr/bin/tr ' ' '\n' | /usr/bin/grep -Fxq admin || continue

    last_login=$(last_login_epoch "$username") || {
        log "Skipping '$username': no parseable login record in local history."
        continue
    }
    (( last_login <= cutoff )) || continue

    home=$(get_home_directory "$username")
    if [[ -z "$home" ]]; then
        log "Skipping '$username': could not determine its home directory."
        continue
    fi

    delete_account "$username" "$home"
done <<< "$users"

log "Finished."
