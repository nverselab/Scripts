#!/bin/bash

####################################################################################################
#
# Copyright (c) 2023, NverseLab.com  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the NverseLab.com nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY NverseLab.com "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL NverseLab.com BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
# Description
#
# The purpose of this script is to create a custom report of inventory data from Jamf Pro for
# reporting, auditing, or archiving records as they exist at runtime.  Inventory object data is pulled
# with the Jamf Pro API, formatted, and stored in the XML folder in the directory where the script was run.
# Specific values are currated into summary CSV tables for general review in the Reports folder.
#
# This script requires an account in Jamf Pro with Auditor or equivalent permissions. This script
# as written will not modify anything in Jamf Pro, but it is always best to use purpose built API accounts
# as a precautionary measure.  It is NOT recommended to use any account with Create, Update, or Delete
# permissions.
#
# This scrip will make an API call for each object ID it finds.  In large environments this may result
# in hundreds or thousands of calls and will take a long time to complete.  Please be patient. 
#
####################################################################################################
#
# HISTORY
#
# v1.0 - 02/13/2023 - Initial WIP release to collect Computers, Devices, Jamf Accounts/Groups, 
#                     Computer Groups, and Device Groups. - Jonathan Nelson
#
####################################################################################################
#
# FUTURE FEATURE IDEAS
#
# - Launcher with Report selection
# - Combined Report View
# - Server Configuration Summary
#   * Sites
#   * Categories
#   * Buildings
#   * Network Segments
#   * GSX Connection
#   * Healthcare Listeners
#   * Infastructure Managers
#   * LDAP Servers
#   * SMTP Server
#   * VPP Accounts
#   * Distribution Points
# - Licensed Software Report
# - Mac Applications Report
# - Configuration Profiles Report (Computers and Devices)
# - Extension Attributes Report (Computers and Devices)
# - Packages Report
# - Patch Management Report
#
####################################################################################################

#############
# Variables #
#############

# Base URL for Jamf Pro API endpoint
base_url="https://yourjamfserver.jamfcloud.com/JSSResource"

# Jamf Pro API credentials
api_username="JamfAPI"
api_password="password"

# Jamf Pro API endpoint URLs
computers_endpoint="$base_url/computers"
devices_endpoint="$base_url/mobiledevices"
accounts_endpoint="$base_url/accounts"
computergroups_endpoint="$base_url/computergroups"
devicegroups_endpoint="$base_url/mobiledevicegroups"

# Get the current date in the format YYYY-MM-DD
current_date=$(date +%Y-%m-%d)

#############################
# Generate Folder Structure #
#############################

# Create the XML and CSV folder if it doesn't exist
if [ ! -d "XML" ]; then
	mkdir XML
	mkdir XML/Computers
	mkdir XML/Devices
	mkdir XML/Access_Accounts
	mkdir XML/Access_Groups
	mkdir XML/Computer_Groups
	mkdir XML/Device_Groups
fi

if [ ! -d "Reports" ]; then
	mkdir Reports
fi

###################
# Computer Report #
###################

# Export all computers
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computers_endpoint" | xmllint --format - > XML/computers.xml

# Create headers for the CSV file
echo "Computer Name,Serial Number,Model,User,Department,Building,Room,OS Version,Enrolled Via DEP,MDM Capable,Last Check-In Time,Site" > Reports/computers_$current_date.csv

# Get a list of all computer IDs
computer_ids=`xmllint --xpath "//id/text()" XML/computers.xml | tr '\n' ' '`

# Loop through each computer ID
for id in $computer_ids; do
	computer_endpoint="$computers_endpoint/id/$id"
	computer_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computer_endpoint"`
	computer_name=`echo "$computer_info" | xmllint --xpath "//computer/general/name/text()" -`
	serial_number=`echo "$computer_info" | xmllint --xpath "//computer/general/serial_number/text()" -`
	user=`echo "$computer_info" | xmllint --xpath "//computer/location/username/text()" -`
	building=`echo "$computer_info" | xmllint --xpath "//computer/location/building/text()" -`
	room=`echo "$computer_info" | xmllint --xpath "//computer/location/room/text()" -`
	department=`echo "$computer_info" | xmllint --xpath "//computer/location/department/text()" -`
	site=`echo "$computer_info" | xmllint --xpath "//computer/general/site/name/text()" -`
	checkin_time=`echo "$computer_info" | xmllint --xpath "//computer/general/last_contact_time/text()" -`
	enrolled_via_dep=`echo "$computer_info" | xmllint --xpath "//computer/general/management_status/enrolled_via_dep/text()" -`
	mdm_capable=`echo "$computer_info" | xmllint --xpath "//computer/general/mdm_capable/text()" -`
	os_version=`echo "$computer_info" | xmllint --xpath "//computer/hardware/os_version/text()" -`
	model=`echo "$computer_info" | xmllint --xpath "//computer/hardware/model/text()" - | tr "," " "` 
	echo "$computer_name,$serial_number,$model,$user,$department,$building,$room,$os_version,$enrolled_via_dep,$mdm_capable,$checkin_time,$site" >> Reports/computers_$current_date.csv
	echo $computer_info | xmllint --format - > "XML/Computers/computerID_$id-SN_$serial_number.xml"
done

#################
# Device Report #
#################

# Export all devices
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$devices_endpoint" | xmllint --format - > XML/devices.xml

# Create headers for the CSV file
echo "Device Name,Serial Number,Model,User,Department,Building,Room,OS Version,Enrollment Method,Supervised,Last Inventory Update,Site" > Reports/devices_$current_date.csv

# Get a list of all device IDs
device_ids=`xmllint --xpath "//mobile_device/id/text()" XML/devices.xml | tr '\n' ' '`

# Loop through each device ID
for id in $device_ids; do
	device_endpoint="$devices_endpoint/id/$id"
	device_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$device_endpoint"`
	device_name=`echo "$device_info" | xmllint --xpath "//mobile_device/general/name/text()" -`
	serial_number=`echo "$device_info" | xmllint --xpath "//mobile_device/general/serial_number/text()" -`
	user=`echo "$device_info" | xmllint --xpath "//mobile_device/location/username/text()" -`
	building=`echo "$device_info" | xmllint --xpath "//mobile_device/location/building/text()" -`
	room=`echo "$device_info" | xmllint --xpath "//mobile_device/location/room/text()" -`
	department=`echo "$device_info" | xmllint --xpath "//mobile_device/location/department/text()" -`
	site=`echo "$device_info" | xmllint --xpath "//mobile_device/general/site/name/text()" -`
	inventory_time=`echo "$device_info" | xmllint --xpath "//mobile_device/general/last_inventory_update/text()" - | tr "," " "`
	enrollement_method=`echo "$device_info" | xmllint --xpath "//mobile_device//general/enrollment_method/text()" -`
	supervised=`echo "$device_info" | xmllint --xpath "//mobile_device/general/supervised/text()" -`
	os_version=`echo "$device_info" | xmllint --xpath "//mobile_device/general/os_version/text()" -`
	model=`echo "$device_info" | xmllint --xpath "//mobile_device/general/model/text()" - | tr "," " "` 
	echo "$device_name,$serial_number,$model,$user,$department,$building,$room,$os_version,$enrollement_method,$supervised,$inventory_time,$site" >> Reports/devices_$current_date.csv
	echo $device_info | xmllint --format - > "XML/Devices/deviceID_$id-SN_$serial_number.xml"
done

########################
# Jamf Accounts Report #
########################

# Export all accounts
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$accounts_endpoint" | xmllint --format - > XML/jamf_access_accounts.xml

# Create headers for the CSV file
echo "Username,Full Name,Email Address,Status,Access Level,Directory User,Privilege Set" > Reports/jamf_access_accounts_$current_date.csv

# Get a list of all account IDs
account_ids=`xmllint --xpath "//user/id/text()" XML/jamf_access_accounts.xml | tr '\n' ' '`

# Loop through each account ID
for id in $account_ids; do
	account_endpoint="$accounts_endpoint/userid/$id"
	account_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$account_endpoint"`
	account_name=`echo "$account_info" | xmllint --xpath "//account/name/text()" -`
	account_fullname=`echo "$account_info" | xmllint --xpath "//account/full_name/text()" -`
	account_email=`echo "$account_info" | xmllint --xpath "//account/email_address/text()" -`
	status=`echo "$account_info" | xmllint --xpath "//account/enabled/text()" -`
	access=`echo "$account_info" | xmllint --xpath "//account/access_level/text()" -`
	directory=`echo "$account_info" | xmllint --xpath "//account/directory_user/text()" -`
	privilege_set=`echo "$account_info" | xmllint --xpath "//account/privilege_set/text()" -`
	echo "$account_name,$account_fullname,$account_email,$status,$access,$directory,$privilege_set" >> Reports/jamf_access_accounts_$current_date.csv
	echo $account_info | xmllint --format - > "XML/Access_Accounts/AccountID_$id-$account_name.xml"
done

######################
# Jamf Groups Report #
######################

# Get a list of all group IDs
group_ids=`xmllint --xpath "//group/id/text()" XML/jamf_access_accounts.xml | tr '\n' ' '`

# Create headers for the CSV file
echo "Group,Access Level,LDAP Server,Privilege Set" > Reports/jamf_access_groups_$current_date.csv

# Loop through each group ID
for id in $group_ids; do
	group_endpoint="$accounts_endpoint/groupid/$id"
	group_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$group_endpoint"`
	group_name=`echo "$group_info" | xmllint --xpath "//group/name/text()" -`
	access=`echo "$group_info" | xmllint --xpath "//group/access_level/text()" -`
	ldap_server=`echo "$group_info" | xmllint --xpath "//group/ldap_server/name/text()" -`
	privilege_set=`echo "$group_info" | xmllint --xpath "//group/privilege_set/text()" -`
	echo "$group_name,$access,$ldap_server,$privilege_set" >> Reports/jamf_access_groups_$current_date.csv
	echo $group_info | xmllint --format - > "XML/Access_Groups/GroupID_$id-$group_name.xml"
done

##########################
# Computer Groups Report #
##########################

# Export all computer groups
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computergroups_endpoint" | xmllint --format - > XML/computer_groups.xml

# Create headers for the CSV file
echo "Group Name,Smart Group,Count,Site" > Reports/computer_groups_$current_date.csv

# Get a list of all computer group IDs
group_ids=`xmllint --xpath "//computer_group/id/text()" XML/computer_groups.xml | tr '\n' ' '`

# Loop through each computer group ID
for id in $group_ids; do
	computergroup_endpoint="$computergroups_endpoint/id/$id"
	group_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computergroup_endpoint"`
	group_name=`echo "$group_info" | xmllint --xpath "//computer_group/name/text()" -`
	smart=`echo "$group_info" | xmllint --xpath "//computer_group/is_smart/text()" -`
	count=`echo "$group_info" | xmllint --xpath "//computer_group/computers/size/text()" -`
	site=`echo "$group_info" | xmllint --xpath "//computer_group/site/name/text()" -`
	echo "$group_name,$smart,$count,$site" >> Reports/computer_groups_$current_date.csv
	echo $group_info | xmllint --format - > "XML/Computer_Groups/groupID_$id-$group_name.xml"
done

########################
# Device Groups Report #
########################

# Export all device groups
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$devicegroups_endpoint" | xmllint --format - > XML/device_groups.xml

# Create headers for the CSV file
echo "Group Name,Smart Group,Count,Site" > Reports/device_groups_$current_date.csv

# Get a list of all device group IDs
group_ids=`xmllint --xpath "//mobile_device_group/id/text()" XML/device_groups.xml | tr '\n' ' '`

# Loop through each computer group ID
for id in $group_ids; do
	devicegroup_endpoint="$devicegroups_endpoint/id/$id"
	group_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$devicegroup_endpoint"`
	group_name=`echo "$group_info" | xmllint --xpath "//mobile_device_group/name/text()" -`
	smart=`echo "$group_info" | xmllint --xpath "//mobile_device_group/is_smart/text()" -`
	count=`echo "$group_info" | xmllint --xpath "//mobile_device_group/mobile_devices/size/text()" -`
	site=`echo "$group_info" | xmllint --xpath "//mobile_device_group/site/name/text()" -`
	echo "$group_name,$smart,$count,$site" >> Reports/device_groups_$current_date.csv
	echo $group_info | xmllint --format - > "XML/Device_Groups/groupID_$id-$group_name.xml"
done