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

printf "Elk server ip: "
read -r ip

if command -v apt > /dev/null 2>&1; then
  printf "Installing dependancies..."
  printf "\n"
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg > /dev/null
  sudo apt-get install apt-transport-https -y > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list > /dev/null
  sudo apt-get update -y > /dev/null
  printf "\nDownloading elastic and kibana\n\n"
  sudo apt-get install elasticsearch kibana > /dev/null &
  spinner $! "Installing"
fi

printf "Enabling and starting elasticsearch\n\n"
sudo systemctl daemon-reload > /dev/null
sudo systemctl enable --now elasticsearch > /dev/null 2>&1 &
spinner $! "Starting elastic"

printf "Getting new password\n\n"
pass=$(echo y | sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -s -u elastic)
printf "\n"

printf "Configuring kibana\n\n"
sudo sed -i s/'#server.host: "localhost"'/"server.host\: \"$ip\""/ /etc/kibana/kibana.yml
sudo /usr/share/kibana/bin/kibana-encryption-keys generate | grep xpack.*: | sudo tee -a /etc/kibana/kibana.yml > /dev/null
sudo systemctl enable --now kibana > /dev/null 2>&1 &
spinner $! "Starting kibana"

token=$(sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)
sudo systemctl status kibana | grep "$ip:5601" > /dev/null
while [ $? -ne 0 ]; do
  sudo systemctl status kibana | grep "code=" > /dev/null
done &
spinner $! "Waiting"

code=$(sudo systemctl status kibana | grep "code=" | awk -F' to ' '{print $2}')

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

printf "Attempting to set up beats\n"

printf "Press enter when you can log into the dashboard\n"
read -r hold

printf "Uploading Alerts to Dashboard"
curl -k -X POST -u elastic:$pass "http://$ip:5601/api/detection_engine/rules/_import" -H "kbn-xsrf: true" --form "file=@Alerting.ndjson"
rm Alerting.ndjson

sudo sh linux_agent.sh $ip $ip $finger $pass
unset $pass
