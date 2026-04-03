#!/bin/bash

echo "This defaults to rolling local passwords only, only run this if you have roll_passwords.ps1, no_change.txt, and words.txt in the current working directory, if you haven't updated the password and domain you should do that"

# Delete domain if you don't need it
domain="changeme"
password="changeme"
echo "Starting password rolling"
for host in $(cat ./hosts.txt); do
	echo "Rolling passwords on host: $host"
	(echo "upload roll_passwords.ps1"; echo "upload no_change.txt"; echo "upload words.txt"; echo "./roll_passwords.ps1 -L"; echo "exit") | evil-winrm -i "$host" -u '$domain\Administrator' -p '$password' 
done
