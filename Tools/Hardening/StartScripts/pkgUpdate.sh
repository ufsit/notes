#!/bin/bash

# Check which package manager is available
if command -v apt-get >/dev/null 2>&1; then
    # Debian/Ubuntu-based distributions
    echo "Updating and upgrading using apt-get"
    sudo apt-get update
    sudo apt-get dist-upgrade -y
    echo -e "\e[32mChecking package integrity:\e[0m"
    dpkg -V | awk '{ if ($1 ~ /..5...../) print "\033[31m" $0 "\033[0m"}'
elif command -v yum >/dev/null 2>&1; then
    # Red Hat-based distributions
    echo "Updating and upgrading using yum"
    sudo yum update -y
    echo -e "\e[32mChecking package integrity:\e[0m"
    /usr/bin/rpm -Va | awk '{ if ($1 ~ /..5...../) print "\033[31m" $0 "\033[0m"}'
elif command -v zypper >/dev/null 2>&1; then
    # SUSE-based distributions
    echo "Updating and upgrading using zypper"
    sudo zypper refresh
    sudo zypper update -y
    echo -e "\e[32mChecking package integrity:\e[0m"
    /usr/bin/zypper verify | grep "MISMATCH"
elif command -v pacman >/dev/null 2>&1; then
    # Arch-based distributions
    echo "Updating and upgrading using pacman"
    sudo pacman -Syu --noconfirm
    echo -e "\e[32mChecking package integrity:\e[0m"
    /usr/bin/pacman -Qkk | awk '$2 == 1 || $2 == 3'
elif command -v /usr/bin/emerge >/dev/null 2>&1; then
    echo "\e[32mChecking package integrity using emerge -K @world\e[0m"
    /usr/bin/emerge -K @worldz
else
    echo -e "\e[33mError: No supported package manager found\e[0m"
fi

