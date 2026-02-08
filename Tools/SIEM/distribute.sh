#!/bin/sh
# Press enter when finished

printf "user: "
read -r user
printf "ip: "
read -r ip

while ! [ -z "$ip"  ]; do
  scp -o ConnectTimeout=5 linux_agent.sh rules.conf archive_install.sh "$user@$ip":~
  printf "ip (Enter when finished): "
  read -r ip
done
