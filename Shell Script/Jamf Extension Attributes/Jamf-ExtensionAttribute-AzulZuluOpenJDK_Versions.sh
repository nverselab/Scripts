#!/bin/bash

# Define the base directory
baseDir="/Library/Java/JavaVirtualMachines"

# Initialize an empty string to hold the results
results=""

# Check for directories with 'zulu' in their names
zuluDirs=$(find "$baseDir" -type d -name "*zulu*" -maxdepth 1)

if [ -z "$zuluDirs" ]; then
    # If no zulu directories are found, echo "Not Installed"
    echo "<result>Not Installed</result>"
else
    # Loop through each zulu directory found
    for dir in $zuluDirs; do
        # Construct the path to the java executable
        javaPath="${dir}/Contents/Home/bin/java"
        # Check if the java executable exists
        if [ -f "$javaPath" ]; then
            # Run 'java -version', capture the output, and extract the line that starts with "openjdk version"
            versionLine=$("$javaPath" -version 2>&1 | grep "openjdk version")
            # Append the extracted line to the results string, followed by a newline character
            results+="${versionLine}\n"
        fi
    done
    # Check if results is not empty, then format it within <result> tags
    if [ -n "$results" ]; then
        # Remove the last newline character from results
        results=${results%\\n}
        # Echo the results within XML tags
        echo -e "<result>${results}</result>"
    else
        echo "<result>Not Installed</result>"
    fi
fi
