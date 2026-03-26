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

read -r ip
read -r remote_ip
read -r pass
read -r token
read -r sudo_pass

echo $sudo_pass | sudo -S -v
(
  while true; do
    sudo -n true
    sleep 60
  done
) &
SUDO_KEEPALIVE_PID=$!

trap 'kill $SUDO_KEEPALIVE_PID' EXIT


if command -v apt > /dev/null 2>&1; then
  printf "Installing dependancies..."
  printf "\n"
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg > /dev/null
  sudo apt-get install apt-transport-https -y > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list > /dev/null
  sudo apt-get update -y > /dev/null
  printf "\nDownloading Kibana\n\n"
  sudo apt-get install -y kibana > /dev/null &
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
  sudo yum install kibana -y -q > /dev/null &
  spinner $! "Installing"
fi

printf "Configuring kibana\n\n"
sudo sed -i s/'#server.host: "localhost"'/"server.host\: \"$remote_ip\""/ /etc/kibana/kibana.yml
sudo /usr/share/kibana/bin/kibana-encryption-keys generate | grep xpack.*: | sudo tee -a /etc/kibana/kibana.yml > /dev/null
sudo systemctl enable --now kibana > /dev/null 2>&1 &
spinner $! "Starting kibana"

systemctl status kibana | grep "$remote_ip:5601" > /dev/null
while [ $? -ne 0 ]; do
  systemctl status kibana | grep "code=" > /dev/null
done &
spinner $! "Waiting"

code=$(systemctl status kibana | grep "code=" | awk -F' to ' '{print $2}')

printf "Finished setting up kibana and elasticsearch\n"
printf "Navigate to $code and paste the enrollment token to complete the script\n"
printf "Enrollment token: $token\n\n"
printf "Dashboard creds: elastic:$pass\n"

finger=$(sudo grep ca_trusted_fingerprint /etc/kibana/kibana.yml)
while [ $? -ne 0 ]; do
  finger=$(sudo grep ca_trusted_fingerprint /etc/kibana/kibana.yml)
done
finger=$(echo $finger | awk -F'ca_trusted_fingerprint: ' '{print $2}' | awk -F'}' '{print $1}') 
printf "CA fingerprint: $finger\n\n"
