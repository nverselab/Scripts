#!/bin/bash
#Mounts the requested share if it doesn't already exist
#Accepts shares in the standard form smb://server/share

#Start seperate process
(
#Initialise variables  
Run_Delay=10
Run_Limit=5
Share_Path=$4
if [ -z "$Share_Path" ]; then
echo "No share path provided, exiting unsuccessfully"
exit 1
else
Share_Name="$(echo $Share_Path | awk -F"/" '{print $NF}')"
fi
Log_Name=$Share_Name
Current_User=$(stat -f%Su /dev/console)

#Notify start of process
mkdir -p /Library/Logs/Sharemounts
echo "$(date) Sharemount for $Share_Name share started" > /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log

#Loop through attempting to mount share as current user
while [[ -z "$(mount | awk '/'$Current_User'/ && /'$Share_Name'/')" ]] && [[ $Run_Count -lt $Run_Limit ]] ; do
let Run_Count=$Run_Count+1
echo "Sharemount attempt $Run_Count to mount $Share_Name" >> /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log
if [[ "$Current_User" ]] && [[ "$Current_User" != "root" ]] && [[ "$(ps -c -u $Current_User | awk /Finder/)" ]]; then
echo "Sharemount user $Current_User and Finder verified proceeding with mount attempt" >> /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log
if [ "$Share_Path" == "home" ];then
Machine_Domain=$(dscl /Active Directory/ -read . SubNodes | awk '{print $2}')
Share_Path="smb:$(dscl "/Active Directory/$Machine_Domain/All Domains" -read /Users/$Current_User SMBHome | awk '{print $2}' | sed 's/\\///g')"
Share_Name="$(echo $Share_Path | awk -F"/" '{print $NF}')"
fi
echo Sharemount attempting to connect to $Share_Path >> /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log
su -m $Current_User -c /usr/bin/osascript<<END
tell application "Finder"
mount volume "$Share_Path"
end tell
END
sleep 1
else
echo "Sharemount user $Current_User or Finder failure refreshing parameters before next attempt" >> /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log
fi
if [[ -z "$(mount | awk '/'$Current_User'/ && /'$Share_Name' /')" ]]; then
sleep $Run_Delay
Current_User=$(stat -f%Su /dev/console)
fi
done

#Test for and output results
if [[ -z "$(mount | awk '/'$Current_User'/ && /'$Share_Name' /')" ]]; then
echo "$(date) Sharemount for $Share_Name share FAILED" >> /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log
else
echo "$(date) Sharemount for $Share_Name share SUCCEEDED" >> /Library/Logs/Sharemounts/Sharemount_"$Log_Name".log
fi
) &
#End seperate process
