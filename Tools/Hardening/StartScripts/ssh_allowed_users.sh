#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 filename"
  exit 1
fi

filename="$1"

if [ ! -f "$filename" ]; then
  echo "Error: File '$filename' not found!"
  exit 1
fi

# Start the variable with 'AllowUsers'
ALLOW_USERS_LINE="AllowUsers"

# Read each user from the file and append to the variable
while IFS= read -r user; do
  # Skip empty lines
  [ -z "$user" ] && continue
  ALLOW_USERS_LINE="$ALLOW_USERS_LINE $user"
done < "$filename"

# Print the final result
echo "The following AllowUsers line would be added to sshd_config:"
echo "$ALLOW_USERS_LINE"
echo
echo "Would you like to write this line to sshd. Make sure you ADD YOUR USER so you can still access the machine (y to accept)"
read -r answer

# If the user types exactly "y", echo "ok". Otherwise do nothing.
if [ "$answer" = "y" ]; then
  echo "$ALLOW_USERS_LINE" >> /etc/ssh/sshd_config
fi

#This script reads from a file as input and adds every user in this file as an allowed user for ssh
#Example: sudo sh SSHAllowedUsers.sh names.txt
