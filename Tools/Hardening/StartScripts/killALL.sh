#!/bin/bash

#BYE-BYE CRON
#--------------------------
#Get a list of all user cron files
cron_files=$(find /var/spool/cron/crontabs/ -type f)

# Loop through each cron file and delete it
for file in $cron_files; do
  rename "s/$file/$file.dead/" $file
  echo "Disabled $file"
done

#Get a list of all /etc/ cron files
cron_files=$(find /etc/cron.* -type f)

# Loop through each cron file and delete it
for file in $cron_files; do
  rename "s/$file/$file.dead/" $file
  echo "Disabled $file"
done

#Removing all anacron tabs
rm /etc/anacrontab

#Get a list of all user anacron files
anacron_files=$(find /home/*/.anacron -type f)

# Loop through each anacron file and delete it
for file in $anacron_files; do
  rename "s/$file/$file.dead/" $file
  echo "Disabled $file"
done

rename "s/crontab/crontab.dead/" /etc/crontab
echo "Disabled /etc/crontab"


systemctl stop cron
#Make sure to manually check /etc/crontab

#BYE-BYE nc
#-------------------------
if command -v apt-get >/dev/null 2>&1; then
  dpkg -l | grep netcat | awk '{print $2}' | xargs apt-get remove -y #Debian
  dpkg -l | grep ncat | awk '{print $2}' | xargs apt-get remove
  apt-get remove ncc
elif command -v yum >/dev/null 2>&1; then
  yum remove nc
elif command -v zypper >/dev/null 2>&1; then
  zypper remove nc
elif command -v pacman >/dev/null 2>&1; then
  pacman -R nc
fi

#BYE-BYE ansible
#-------------------------------
if command -v apt-get >/dev/null 2>&1; then
  apt-get remove ansible
elif command -v yum >/dev/null 2>&1; then
  yum remove ansible
elif command -v zypper >/dev/null 2>&1; then
  zypper remove ansible
elif command -v pacman >/dev/null 2>&1; then
  pacman -R ansible
fi

#BYE-BYE at
#-------------------------------
if command -v apt-get >/dev/null 2>&1; then
  apt-get remove at
elif command -v yum >/dev/null 2>&1; then
  yum remove at
elif command -v zypper >/dev/null 2>&1; then
  zypper remove at
elif command -v pacman >/dev/null 2>&1; then
  pacman -R at
fi


echo -e "\e[33mCheck for any sus services:\e[0m"
systemctl --type=service --state=running
