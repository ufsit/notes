#!/bin/sh
# Press enter when finished

printf "user: "
read -r user
printf "password: "
read -r pass
printf "ip: "
read -r ip
printf "elastic ip: "
read -r elastic
printf "kibana ip: "
read -r kibana
printf "fingerprint: "
read -r finger
printf "elastic password: "
read -r password

while ! [ -z "$ip"  ]; do
  echo $ip
  sshpass -p "$pass" scp -o ConnectTimeout=5 -o StrictHostKeyChecking=no linux_agent.sh rules.conf archive_install.sh "$user@$ip":~
  sshpass -p "$pass" ssh -n -o StrictHostKeyChecking=no "$user"@"$ip" "sudo sh linux_agent.sh" << EOF
$elastic
$kibana
$finger
$password
EOF
  printf "ip (Enter when finished): "
  read -r ip
done
