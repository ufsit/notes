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

for beat in auditbeat filebeat packetbeat; do
  curl -L https://artifacts.elastic.co/downloads/beats/$beat/$beat-8.19.6-linux-x86_64.tar.gz -o $beat.tar.gz
  tar xzf $beat.tar.gz
  rm $beat.tar.gz
  mv $beat-* /etc/$beat
  mv /etc/$beat/$beat /usr/bin/
  sed -i "s/\${path.config}/\/etc\/$beat/g" /etc/$beat/$beat.yml
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
