#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as run (i.e. sudo sh linux_agent.sh)" 1>&2
  exit 1
fi

hostname=$(hostname 2>/dev/null || hostnamectl hostname)
if [ $# -lt 3 ]; then
  printf "ELK Server ip: "
  read -r ip
  printf "CA Fingerprint: "
  read -r finger

  OLD_STTY_SETTINGS=$(stty -g)
  stty -echo
  trap 'stty "$OLD_STTY_SETTINGS"; exit' EXIT INT HUP TERM

  printf "Elastic password: "
  read -r pass
  stty "$OLD_STTY_SETTINGS"
  printf "\n"
else
  ip=$1
  finger=$2
  pass=$3
fi

if [ $# -lt 3 ]; then 
  if command -v apt > /dev/null 2>&1; then
    if ! [ -f "/etc/apt/sources.list.d/elastic-8.x.list" ]; then
      printf "Installing dependancies..."
      printf "\n"
      wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg > /dev/null
      apt-get install apt-transport-https curl -y > /dev/null
      echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list > /dev/null
      apt-get update -y > /dev/null
    fi
    printf "\nInstalling beats...\n"
    apt-get install auditbeat filebeat packetbeat -y -qq > /dev/null
  elif command -v yum > /dev/null 2>&1; then
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    cat >> /etc/yum.repos.d/elastic.repo << EOL
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL
    yum install auditbeat filebeat packetbeat curl -y -q > /dev/null
  elif command -v zypper > /dev/null 2>&1; then 
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    cat >> /etc/zypp/repos.d/elastic.repo << EOL
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL
    zypper refresh > /dev/null
    zypper --non-interactive install filebeat auditbeat packetbeat curl > /dev/null
  fi
else
    apt-get install auditbeat filebeat packetbeat curl -y > /dev/null
fi
result=$(curl -k -u elastic:$pass -X POST "https://$ip:9200/_security/api_key?pretty" -H 'Content-Type: application/json' -d"
{
  \"name\": \"$hostname\", 
  \"role_descriptors\": {
    \"beat_writer\": { 
      \"cluster\": [\"monitor\", \"read_ilm\", \"read_pipeline\"],
      \"index\": [
        {
          \"names\": [\"filebeat-*\", \"auditbeat-*\", \"packetbeat-*\", \"winlogbeat-*\"],
          \"privileges\": [\"view_index_metadata\", \"create_doc\", \"auto_configure\"]
        }
      ]
    }
  }
}
" -s)
id=$(echo "$result" | awk -F'"' '/"id"/{print $4}')
key=$(echo "$result" | awk -F'"' '/api_key/{print $4}')
api_key="$id:$key"

for beat in auditbeat filebeat packetbeat; do
  $beat setup -E setup.kibana.host="http://$ip:5601" -E setup.kibana.username="elastic" -E setup.kibana.password="$pass" -E output.elasticsearch.hosts="[\"https://$ip:9200\"]" -E output.elasticsearch.username="elastic" -E output.elasticsearch.password="$pass" -E output.elasticsearch.ssl.enabled="true" -E output.elasticsearch.ssl.ca_trusted_fingerprint="$finger"
done

for beat in auditbeat filebeat packetbeat; do
  cat >> /etc/$beat/$beat.yml << EOL
output.elasticsearch.hosts: ["https://$ip:9200"]
output.elasticsearch.api_key: "$api_key"
output.elasticsearch.ssl.enabled: true
output.elasticsearch.ssl.ca_trusted_fingerprint: "$finger"
EOL
done

cat >> /etc/packetbeat/packetbeat.yml << EOL
packetbeat.interfaces.type: af_packet
processors:
  - drop_event:
      when:
        or:
          - not:
              has_fields: ['source.ip', 'destination.ip']
          - and:
            - equals:
                destination.ip: "$ip"
            - equals:
                destination.port: 9200
          - and:
            - equals:
                destination.ip: 'ff02::2'
            - equals:
                network.transport: 'ipv6-icmp'
EOL
for beat in auditbeat filebeat packetbeat; do
  sed -i 's/hosts: \["localhost/# hosts: \["localhost/g' /etc/$beat/$beat.yml
  $beat test config > /dev/null
  if [ $? -ne 0 ]; then
    printf "Check /etc/$beat/$beat.yml\n"
  fi
  $beat test output > /dev/null
  if [ $? -ne 0 ]; then
    printf "Output test failed for $beat\n"
  fi
done
curl -q https://raw.githubusercontent.com/ufsit/shreksophone1/refs/heads/main/rules.conf -o /etc/auditbeat/audit.rules.d/rules.conf

printf "Starting beats...\n"

if command -v systemctl > /dev/null 2>&1; then
  systemctl daemon-reload > /dev/null && systemctl enable --now auditbeat filebeat packetbeat > /dev/null
  if [ $(auditbeat show audit-rules | wc -l) -eq 1 ]; then
    systemctl restart auditbeat
  fi
fi

printf "Success!\n"
