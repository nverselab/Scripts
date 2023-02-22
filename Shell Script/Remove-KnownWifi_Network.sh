#!/bin/bash

###############################
#                             #
# Note: Requires IBM Notifier #
#                             #
###############################

# IBM Notifier Path
IBMpath="/Applications/Utilities/IBM\ Notifier.app/Contents/MacOS/IBM\ Notifier"

##########################  DO NOT MODIFY BELOW THIS LINE  ##########################

# Get the interface name for the Wi-Fi adapter
interface=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $2}')

#!/bin/bash

# Get the list of known Wi-Fi networks on en1
networks=$(networksetup -listpreferredwirelessnetworks $interface | sed 's/\t//g')

# Split the list into an array
IFS=$'\n' read -d '' -ra networks_array <<< "$networks"

# Remove the first item in the array
unset "networks_array[0]"
networks_array=("${networks_array[@]}")

# Build a variable with each item in the array on a separate line
networks_str=""
for network in "${networks_array[@]}"
do
  networks_str="${networks_str}${network}\n"
done

# Prompt user for Jamf Pro base_url
IBMwifi=`echo "-type popup -silent -title \"Known Wifi Networks\" -accessory_view_type dropdown -accessory_view_payload \"/placeholder Choose the Wi-Fi network to forget /list $networks_str \" -main_button_label \"Remove\" -secondary_button_label \"Cancel\""`
IBMcommand="$IBMpath $IBMwifi"

wifiSelection=$(echo $IBMcommand | sh)

if [ ! -z $wifiSelection ]; then
  echo "Selected $wifiSelection...  Removing $interface ${networks_array[$wifiSelection]}"
  sudo networksetup -removepreferredwirelessnetwork $interface "${networks_array[$wifiSelection]}"
else
  echo "Action Cancelled.  Exiting."
  exit 0
fi
