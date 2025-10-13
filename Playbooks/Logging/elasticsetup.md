# Playbook for setting up Elastic
Work in progress...

Will be the full setup for Elastic logging
## Elasticsearch
1. `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg`
2. `sudo apt-get install apt-transport-https` 
3. `echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list`
4. `sudo apt-get update && sudo apt-get install elasticsearch`
**Make sure to save the password this spits out**
5. 
```
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```
## Kibana
Assuming you did the first 4 steps of Elasticsearch setup
1. `sudo apt-get install kibana` (This may take a while)
2. `sudo sed -i s/'#server.host: "localhost"'/'server.host: "0.0.0.0"'/ /etc/kibana/kibana.yml`
3. `/usr/share/kibana/bin/kibana-encryption-keys generate | tail -n 4 | head -n 3 | sudo tee -a /etc/kibana/kibana.yml`
4. 
```
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana
```
5. `/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana` (Copy this token)
6. `systemctl status kibana | grep 0.0.0.0` (Navigate to the url with the `?code=` argument and replace `0.0.0.0` with the machine ip)
7. Paste in the enrollment token and enroll. This may take a few minutes, so start installing metricbeat while waiting
8. Navigate to Stack Management -> Users -> Create User
9. Create the user `beat_manager` and give it a password
10. Assign this user the roles `remote_monitoring_agent` and `remote_monitoring_collector`

## Metricbeat
Assuming you did the first 4 steps of Elasticsearch setup
1. `sudo apt-get install metricbeat`
2. 
```
metricbeat modules enable elasticsearch-xpack
metricbeat modules disable system
```
3. `sudo grep ca_trusted_fingerprint /etc/kibana/kibana.yml` 
**Save this fingerprint somewhere the team can access it**
4. Edit `/etc/metricbeat/modules.d/elasticsearch-xpack.yml` to look like:
```
- module: elasticsearch
  xpack.enabled: true
  period: 10s
  hosts: ["https://localhost:9200"]
  username: beat_manager
  password: <created_password>
  ssl:
    enabled: true
    ca_trusted_fingerprint: "<fingerprint>"
```
5. Edit `/etc/metricbeat/metricbeat.yml` and edit the section starting with `output.elasticsearch` to be:
```
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  preset: balanced
  username: "beat_manager"
  password: "<created_password>"
  ssl:
    enabled: true
    certificate_authorities: ["/etc/elasticsearch/certs/http_ca.crt"]
```
6. `sudo systemctl daemon-reload && sudo systemctl enable metricbeat --now`
7. Give it a few minutes and check Stack Monitoring on the elastic dashboard

**The elastic server should now be set up! Continue to Agent Setup Playbook**
