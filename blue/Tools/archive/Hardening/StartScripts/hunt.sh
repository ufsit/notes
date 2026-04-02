#!/bin/bash

#Checks for potentially malicious files (e.g. redteam, recently modified, orphaned, promiscuous mode). Part of the code is commented out (e.g. processes in unusual directories and not installed using standard package system) however, these tend to have a lot of output with many false alarms.

# Checking for redteam files
echo -e "\e[31mRedteam files found:\e[0m"
find / -type f -iname "*redteam*" -o -type d -iname "*redteam*" 2> /dev/null

# Checking for processes running in strange places - BAD CODE
#echo -e "\e[33mProcesses running in unusual directories\e[0m"
#ps aux | awk '$11 !~ /^\/(sbin|bin|usr|var|lib|sys|proc|dev|tmp|run|root|home|etc)\// {print}'

# Checking for recently modified files
echo -e "\e[33mRecently modified files:\e[0m"
find / -xdev -mmin -60 -ls 2>/dev/null

# Finding packages installed not using dpkg (Debian) or rpm (CentOS)
#if [ -x "$(command -v dpkg)" ]; then
#    echo -e "\e[33mPackages installed not using dpkg (Debian):\e[0m"
#    comm -13 <(dpkg -l | awk '/^ii/ {print $2}' | sort -u) <(find / -type f -exec dpkg -S {} + 2>/dev/null | cut -d: -f1 | sort -u)
#fi

#if [ -x "$(command -v rpm)" ]; then
#    echo -e "\e[33,Packages installed not using rpm (CentOS):\e[0m"
#    comm -13 <(rpm -qa | sort -u) <(find / -type f -exec rpm -qf {} + 2>/dev/null | sort -u)
#fi

# Find the orphans!
# Find all files and directories with no user
NOUSER=$(find / \( -type f -o -type d \) -nouser 2>/dev/null)

# Find all files and directories with no group
NOGROUP=$(find / \( -type f -o -type d \) -nogroup 2>/dev/null)

# Combine the lists of files and directories with no user or no group
ORPHANED=$(echo -e "$NOUSER\n$NOGROUP" | sort | uniq)

# Check if there are any orphaned files or directories
if [[ -z "$ORPHANED" ]]; then
    echo "None!"
else
    # Print the list of orphaned files and directories
    echo -e "\e[31mOrphaned files and directories:\e[0m"
    while IFS= read -r file; do
        ls -ld "$file"
    done <<< "$ORPHANED"
fi

# look for interfaces in promiscuous mode
echo -e "\e[33mInterfaces in promiscuous mode:\e[0m"
ip link | grep PROMISC
