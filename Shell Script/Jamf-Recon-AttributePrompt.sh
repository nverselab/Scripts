#!/bin/bash

###############################
#                             #
# Note: Requires IBM Notifier #
#                             #
###############################

# IBM Notifier Path
IBMpath="/Applications/Utilities/IBM\ Notifier.app/Contents/MacOS/IBM\ Notifier"

##########################  DO NOT MODIFY BELOW THIS LINE  ##########################

#########################
# Static attribute list #
#########################

# Define static attributes (one per line will appear in the dropdown)
attributes=(
  "marketing"
  "accounting"
  "administration"
  "nursing"
  "pediatrics"
  "oncology"
)

# Build list string for IBM Notifier (each item on its own line)
attrs_str=""
for a in "${attributes[@]}"; do
  attrs_str+="${a}\n"
done

# Prompt user to select an attribute from the dropdown
IBMpayload="-type popup -silent -title \"Please select your role\" -accessory_view_type dropdown -accessory_view_payload \"/placeholder Choose attribute /list ${attrs_str} \" -main_button_label \"Set\" -secondary_button_label \"Cancel\""
IBMcommand="$IBMpath $IBMpayload"

# IBM Notifier prints the selected index; capture it
selection_index=$(echo "$IBMcommand" | sh)

if [[ -z "$selection_index" ]]; then
  echo "Action Cancelled. Exiting."
  exit 0
fi

# Validate index is numeric
if ! [[ "$selection_index" =~ ^[0-9]+$ ]]; then
  echo "Unexpected selection returned: $selection_index" >&2
  exit 1
fi

selection="${attributes[$selection_index]}"
if [[ -z "$selection" ]]; then
  echo "Invalid selection index: $selection_index" >&2
  exit 1
fi

echo "Selected attribute: $selection (index $selection_index)"

# Run jamf recon to set position to the chosen attribute (as requested)
# The user asked: run `jamf recon --position $selection`
echo "Running: jamf recon --position $selection"
sudo jamf recon --position "$selection"
