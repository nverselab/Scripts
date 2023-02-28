#!/bin/bash

# Enter the path of the file you want to check the modified date for
file_path="/path/to/your/file"

# Check if the file exists
if [ ! -e "$file_path" ]; then
	echo "<result>File not found</result>"
	exit 0
fi

# Get the modified date of the file in seconds since the Unix epoch
modified_date=$(stat -f "%m" "$file_path")

# Convert the modified date from seconds since the Unix epoch to YYYY-MM-DD hh:mm:ss format
formatted_date=$(date -r "$modified_date" +"%Y-%m-%d %H:%M:%S")

# Print the formatted date to the console
echo "<result>$formatted_date</result>"
