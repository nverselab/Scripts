#/bin/bash

# Make sure to set the desired PolicyID for the Self Service item you want to open in the Paramter Value $4 in Jamf Pro.
policyID=${4}

prompt=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -description "To remediate the detected threat, please open Self Service and click Remediate." -button1 "Ok" -title "Remediation Required" -windowType hud -defaultButton 1 -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns" -cancelButton 2)

if [[ "$prompt" == "0" ]]
	then
		open "jamfselfservice://content?entity=policy&id=$policyID&action=view"
	
fi