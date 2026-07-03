#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root (i.e. sudo sh linux_agent.sh)" 1>&2
  exit 1
fi

hostname=$(hostname 2>/dev/null || hostnamectl hostname)
if [ $# -lt 4 ]; then
  printf "Elastic Server ip: "
  read -r ip
  printf "Kibana Server ip: "
  read -r kibana_ip
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
  kibana_ip=$2
  finger=$3
  pass=$4
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
    apt-get install auditbeat filebeat packetbeat curl -y -qq > /dev/null
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
  elif command -v apk > /dev/null 2>&1; then
    apk update > /dev/null 2>&1 && apk add curl > /dev/null 2>&1
    tar xzf alpine-beats.tar.gz
    rm alpine-beats.tar.gz
    for beat in auditbeat filebeat packetbeat; do
      mv $beat /usr/bin
      curl -L -O -s https://artifacts.elastic.co/downloads/beats/$beat/$beat-8.19.6-linux-x86_64.tar.gz
      tar xzf $beat-8.19.6-linux-x86_64.tar.gz
      rm $beat-8.19.6-linux-x86_64.tar.gz
      mv $beat-8.19.6-linux-x86_64 /etc/$beat
      rm /etc/$beat/$beat
      sed -i "s/\${path.config}/\/etc\/$beat/g" /etc/$beat/$beat.yml
      cat >> /etc/init.d/$beat << EOL
#!/sbin/openrc-run

description="Elastic $beat service"

command="/usr/bin/$beat"
command_args="-c /etc/$beat/$beat.yml"
pidfile="/run/$beat.pid"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --owner root:root --mode 755 /etc/$beat/logs
    checkpath --directory --owner root:root --mode 755 /etc/$beat/data
}

start() {
    ebegin "Starting $beat"
    start-stop-daemon --start --exec "\$command" --pidfile "\$pidfile" \
        --background --make-pidfile -- \
        \$command_args
    eend \$?
}

stop() {
    ebegin "Stopping $beat"
    start-stop-daemon --stop --pidfile "\$pidfile" --retry 5
    eend \$?
}

restart() {
    ebegin "Restarting $beat"
    if [ -f "\$pidfile" ]; then
        start-stop-daemon --stop --pidfile "\$pidfile" --retry 5
        sleep 1
    fi

    start-stop-daemon --start --exec "\$command" --pidfile "\$pidfile" \
        --background --make-pidfile -- \
        \$command_args
    eend \$?
}
EOL
      chmod +x /etc/init.d/$beat
      rc-update add $beat default
    done
    sed -i '50,77 d' /etc/auditbeat/auditbeat.yml
    rm -rf logs data
  else
    sh archive_install.sh 
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


if [ $# -gt 1 ]; then
  printf "~-~-~-~-~-Server install is: %s\n" "$server_install"
  for beat in auditbeat filebeat packetbeat; do
    $beat setup -E setup.kibana.host="http://$kibana_ip:5601" -E setup.kibana.username="elastic" -E setup.kibana.password="$pass" -E output.elasticsearch.hosts="[\"https://$ip:9200\"]" -E output.elasticsearch.username="elastic" -E output.elasticsearch.password="$pass" -E output.elasticsearch.ssl.enabled="true" -E output.elasticsearch.ssl.ca_trusted_fingerprint="$finger" -c /etc/$beat/$beat.yml --path.home "/etc/$beat/"
  done
fi

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

cat >> /etc/auditbeat/auditbeat.yml << EOL
processors:
  - drop_event:
      when:
        or:
          - and:
            - equals:
                destination.ip: "$ip"
            - or:
              - equals:
                  destination.port: 9200
              - equals:
                  destination.port: 5601
          - equals:
              process.name: 'packetbeat'
          - equals:
              process.name: 'auditbeat'
          - equals:
              process.name: 'filebeat'
          - equals:
              destination.ip: 127.0.0.1
          - equals:
              destination.ip: 127.0.0.53
EOL

sed -i "s/- \/etc/- \/etc\n  - \/tmp\n  - \/var\/tmp\n  - \/var\/spool\n  - \/var\/www\n  - \/lib\n  - \/lib64\n  - \/usr\/lib\n  - \/usr\/lib64\n  - \/var\/lib\n  - \/usr\/lib\n  - \/usr\/share\n  - \/usr\/local\n  - \/opt\n  recursive: true\n  exclude_files:\n  - '\.sw.$'\n  - '\.swpx$'\n  - '~$'\n  - '\.temp$'\n  - '\/\#.*\#$'\n  - '\\.save$'/g" /etc/auditbeat/auditbeat.yml

# Configure filebeat for modesc
sed -i "s/  id:.*/  id: modsec/g" /etc/filebeat/filebeat.yml
sed -i "s/  enabled:.*/  enabled: true/g" /etc/filebeat/filebeat.yml
sed -i "s/\- \/var\/log\/\*\.log/\- \/root\/blue\/webandaid\/*.json\n  processors:\n    \- decode_json_fields:\n        fields: \[\"message\"\]\n        target: \"\"\n        add_error_key: true\n        max_depth: 2\n        expand_keys: true\n        process_array: true\n        overwrite_keys: true\n/g" /etc/filebeat/filebeat.yml

# Automatically ingest system logs (ex: auth.log)
filebeat -c /etc/filebeat/filebeat.yml modules enable system
sed -i "s/false/true/g" /etc/filebeat/modules.d/system.yml

for beat in auditbeat filebeat packetbeat; do
  sed -i 's/hosts: \["localhost/# hosts: \["localhost/g' /etc/$beat/$beat.yml
  $beat test config -c /etc/$beat/$beat.yml > /dev/null
  if [ $? -ne 0 ]; then
    printf "Check /etc/$beat/$beat.yml\n"
  fi
  $beat test output -c /etc/$beat/$beat.yml > /dev/null
  if [ $? -ne 0 ]; then
    printf "Output test failed for $beat\n"
  fi
done
mv rules.conf /etc/auditbeat/audit.rules.d/

printf "Starting beats...\n"

if command -v systemctl > /dev/null 2>&1; then
  systemctl status auditd > /dev/null 2>/dev/null
  if [ $? -eq 0 ]; then
    service auditd stop
    if [ $? -ne 0 ]; then
      kill -9 $(ps -aux | grep '/auditd' | grep root | awk '{print $2}')
    fi
    systemctl disable auditd
  fi
  systemctl status graylog* > /dev/null 2>/dev/null
  if [ $? -eq 0 ]; then
    systemctl disable --now gray*
  fi
  systemctl status wazuh* > /dev/null 2>/dev/null
  if [ $? -eq 0 ]; then
    systemctl disable --now wazuh*
  fi
  systemctl status splunk* > /dev/null 2>/dev/null
  if [ $? -eq 0 ]; then
    systemctl disable --now splunk*
  fi
  systemctl daemon-reload > /dev/null && systemctl enable --now auditbeat filebeat > /dev/null
  if [ $(auditbeat show audit-rules | wc -l) -eq 1 ]; then
    systemctl restart auditbeat
  fi
elif command -v service > /dev/null 2>&1; then
  for beat in auditbeat filebeat; do
    service auditd stop
    service $beat start
  done
fi

printf "Success!\n"
