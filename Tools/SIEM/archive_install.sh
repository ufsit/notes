#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root (i.e. sudo sh linux_agent.sh)" 1>&2
  exit 1
fi
if [ $# -lt 4 ]; then
  echo "This script is not meant to be run on its own. Run ./linux_install.sh instead"
  exit 1
fi
if ! command -v curl; then
  echo "This script requires curl to be installed. Please install it now"
  exit 1
fi

ip=$1
finger=$2
pass=$3
hostname=$4
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

cd /etc
for beat in auditbeat filebeat packetbeat; do
  curl -L -O https://artifacts.elastic.co/downloads/beats/$beat/$beat-8.19.6-linux-x86_64.tar.gz -o $beat.tar.gz
  tar xzf $beat.tar.gz
  rm $beat.tar.gz
  $beat setup -E setup.kibana.host="http://$ip:5601" -E setup.kibana.username="elastic" -E setup.kibana.password="$pass" -E output.elasticsearch.hosts="[\"https://$ip:9200\"]" -E output.elasticsearch.username="elastic" -E output.elasticsearch.password="$pass" -E output.elasticsearch.ssl.enabled="true" -E output.elasticsearch.ssl.ca_trusted_fingerprint="$finger"
  sed -i 's/hosts: \["localhost/# hosts: \["localhost/g' /etc/$beat/$beat.yml
  cat >> /etc/$beat/$beat.yml << EOL
output.elasticsearch.hosts: ["https://$ip:9200"]
output.elasticsearch.api_key: "$api_key"
output.elasticsearch.ssl.enabled: true
output.elasticsearch.ssl.ca_trusted_fingerprint: "$finger"
EOL
  /etc/$beat/$beat -c /etc/$beat/$beat.yml test config > /dev/null
  if [ $? -ne 0 ]; then
    printf "Check /etc/$beat/$beat.yml\n"
  fi
  /etc/$beat/$beat -c /etc/$beat/$beat.yml test output > /dev/null
  if [ $? -ne 0 ]; then
    printf "Output test failed for $beat\n"
  fi
  cat >> /etc/systemd/system/$beat.service << EOL
[Unit]
Description=$beat service to send logs to elasticsearch
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/$beat/$beat -c /etc/$beat/$beat.yml

[Install]
WantedBy=multi-user.target
EOL
done
curl -q https://raw.githubusercontent.com/ufsit/shreksophone1/refs/heads/main/rules.conf -o /etc/auditbeat/audit.rules.d/rules.conf
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
systemctl enable --now auditbeat filebeat packetbeat
