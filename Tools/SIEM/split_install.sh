#!/bin/sh

# Function to display the waiting animation
spinner() {
  local pid="$1"
  local delay="0.1" # Adjust the speed of the spinner
  local spinstr='|/-\\'
  local i=0

  # Hide cursor
  printf "\033[?25l"
  
  while ps -p "$pid" >/dev/null 2>&1; do
    i=$((i + 1))
    case $((i % 4)) in
      0) c='...' ;;
      1) c=' ..' ;;
      2) c='. .' ;;
      3) c='.. ' ;;
    esac
    printf "\r$2%s" "$c"
    sleep "$delay"
  done

    # Restore cursor
    printf "\033[?25h"
    printf "\r$2 Done.\n"
}

printf "Elasticsearch Server ip: "
read -r ip
printf "Kibana Dashboard ip: "
read -r remote_ip
printf "Kibana Machine Username: "
read -r remote_user
printf "Kibana Machine Password: "
OLD_STTY_SETTINGS=$(stty -g)
stty -echo
trap 'stty "$OLD_STTY_SETTINGS"; exit' EXIT INT HUP TERM
read -r pass
stty "$OLD_STTY_SETTINGS"

if command -v apt > /dev/null 2>&1; then
  printf "Installing dependancies..."
  printf "\n"
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg > /dev/null
  sudo apt-get install apt-transport-https -y > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list > /dev/null
  sudo apt-get update -y > /dev/null
  printf "\nDownloading elasticsearch\n\n"
  sudo apt-get install -y elasticsearch > /dev/null &
  spinner $! "Installing"
elif command -v yum > /dev/null 2>&1; then
  printf "Installing dependancies..."
  printf "\n"
  sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
  sudo cat >> /etc/yum.repos.d/elastic.repo << EOL
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL
  sudo yum install elasticsearch -y -q > /dev/null &
  spinner $! "Installing"
fi

printf "Enabling and starting elasticsearch\n\n"
sudo systemctl daemon-reload > /dev/null
sudo systemctl enable --now elasticsearch > /dev/null 2>&1 &
spinner $! "Starting elastic"

printf "Getting new password\n\n"
pass=$(echo y | sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -s -u elastic)
printf "\n"
token=$(sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)

scp split_install_part2.sh "$remote_user@$remote_ip":~/split_install_part2.sh
ssh $remote_user@$remote_ip "sudo -S sh ~/split_install_part2.sh" <<EOF
$remote_pass
$ip
$remote_ip
$pass
$token
$remote_pass
EOF

printf "Paste Printed out Fingerprint: \n"
read -r finger

printf "Attempting to set up beats\n"

printf "Press enter when you can log into the dashboard\n"
read -r hold

printf "Uploading Alerts to Dashboard"
if [ ! -e "./Alerting.ndjson" ]; then
  curl -L -O -s "https://github.com/ufsit/blue/raw/refs/heads/main/logging/Alerting.ndjson"
fi
curl -k -X POST -u elastic:$pass "http://$remote_ip:5601/api/detection_engine/rules/_import" -H "kbn-xsrf: true" --form "file=@Alerting.ndjson"
rm Alerting.ndjson

scp linux_agent.sh rules.conf "$remote_user@$remote_ip":~/linux_agent.sh

sudo sh linux_agent.sh $ip $remote_ip $finger $pass

ssh "$remote_user@$remote_ip" "sudo -S sh ./linux_agent.sh" <<EOF
$remote_pass
$ip
$remote_ip
$finger
$pass
EOF
