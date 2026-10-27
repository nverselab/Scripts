#!/bin/zsh

:<<'ABOUT_THIS_SCRIPT'
-----------------------------------------------------------------------
	Written by:William Smith
	Technical Enablement Manager
	Jamf
	bill@talkingmoose.net
	https://gist.github.com/talkingmoose/b3553675a613176b35c27b5c5028e0c2
	
	Originally posted: July 31, 2026
	Updated: August 2, 2026
			 • Added second command to find all Rosetta-dependent apps
			   and report usage.
			 September 20, 2026
			 • Added support for system_profiler data returned from Golden Gate.
			 • Corrected error where an empty apps list would result in "All
			   apps support Apple silicon".
			 • Added support for similar apps in different locations.
			 • List apps with full paths
	Purpose: Jamf Pro extension attribute to identity Intel-apps
	requiring Rosetta to run on Apple Silicon Macs. It will list
	apps that have launched at least once on the computer as well as apps
	never used.

-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# list legacy apps in use with bundle identifiers

system_profilerData=$( /usr/sbin/system_profiler -json SPLegacySoftwareDataType 2>/dev/null )

# list bundle IDs and paths of legacy apps in use
# reference: https://stackoverflow.com/questions/47939901/jq-how-to-match-one-of-array-and-get-property-value

intelOnlyAppsInUse=$( /usr/bin/jq -r '
	.. | objects
	| select(.has_native_version == "has_native_version_no" or .reason == "reason_x86_only")
	| .responsible_identity? // empty
	| select(.identity_bundle_id? != null and .identity_bundle_id != ""
		and .identity_path? != null and .identity_path != "")
	| [.identity_bundle_id, .identity_path] | @tsv
' <<< "$system_profilerData" )

# trim app paths to end with ".app"

intelOnlyAppsInUse=$( /usr/bin/sed 's/.app.*$/.app/g' <<< "$intelOnlyAppsInUse" )

# list all legacy apps, in use or not, with bundle identifiers

spotlightData=$( /usr/bin/mdfind 'kMDItemExecutableArchitectures == "x86_64" && kMDItemExecutableArchitectures != "arm64" && kMDItemContentType == "com.apple.application-bundle"' )

while read appPath;
do
	appBundleID=$( /usr/bin/defaults read "$appPath/Contents/Info.plist" CFBundleIdentifier 2>/dev/null )
	if [[ "$appBundleID" ]]; then
		allIntelOnlyApps=$( /bin/cat <<< "$allIntelOnlyApps" <<< "$appBundleID" <<< "$appPath" )
	fi
done <<< "$spotlightData"

# clean up lines and list bundle IDs and paths of all legacy apps

allIntelOnlyApps=$( /usr/bin/tail -n +2 <<< "$allIntelOnlyApps" | /usr/bin/paste - - )

# compare intelOnlyAppsInUse with allIntelOnlyApps and create list of never launched Intel-only apps

if [[ "$intelOnlyAppsInUse" ]]; then
	while read anApp;
	do
		allIntelOnlyApps=$( /usr/bin/grep -v "$anApp" <<< "$allIntelOnlyApps" )
	done <<< "$intelOnlyAppsInUse"
fi

# strip bundle IDs from both lists

intelOnlyAppsInUse=$( /usr/bin/awk -F \t '{ print $2 }' <<< "$intelOnlyAppsInUse" | /usr/bin/sort )
intelOnlyAppsNeverLaunched=$( /usr/bin/awk -F \t '{ print $2 }' <<< "$allIntelOnlyApps" | /usr/bin/sort )

# report to Jamf Pro

if [[ "$intelOnlyAppsInUse" = "" ]] && [[ "$intelOnlyAppsNeverLaunched" = "" ]]; then
	echo "<result>All apps support Apple Silicon</result>"
elif [[ ! "$intelOnlyAppsInUse" = "" ]] && [[ "$intelOnlyAppsNeverLaunched" = "" ]]; then
	echo "<result>IN USE
$intelOnlyAppsInUse</result>"
elif [[ "$intelOnlyAppsInUse" = "" ]] && [[ ! "$intelOnlyAppsNeverLaunched" = "" ]]; then
	echo "<result>NEVER USED
$intelOnlyAppsNeverLaunched</result>"
elif [[ ! "$intelOnlyAppsInUse" = "" ]] && [[ ! "$intelOnlyAppsNeverLaunched" = "" ]]; then
	echo "<result>IN USE
$intelOnlyAppsInUse
NEVER USED
$intelOnlyAppsNeverLaunched</result>"
fi
