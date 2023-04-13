#/bin/bash

# Define function to check commands
check_command() {
  if ! output="$("$@" 2>&1)"; then
    echo "Error on line ${BASH_LINENO[0]}: Command '$*' failed with output:" >&2
    echo "$output" >&2
    #exit 1
  fi
}

# Example usage of the check_command function
check_command ls -l # Successful Example
check_command date -j 20220431120000 +%s # Failed Example