# Playbook for setting up Log forwarding
Work in progress...

Will eventually include all relevant operating systems
## Script
This script has been tested on:
- Ubuntu 16,20,24
- Centos 7
- Fedora 30
- Debian 9
- openSuse Leap 16
- Alpine 3.10.9

You can find the script [here](/Tools/SIEM/linux_agent.sh)

## Installing
### Debian-Like (apt package manager)
Some initial setup (skip if on the elastic server)[^1]
1. `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg`
2. 
```
sudo apt-get install apt-transport-https curl -y
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update
sudo apt-get install auditbeat filebeat packetbeat -y
```

### Redhat (yum/dnf package manager)[^1]
1. `sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch`
2. 
```
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
```
3. `sudo yum install auditbeat filebeat packetbeat curl -yq`

### OpenSUSE (zypper package manager)[^1]
1. `sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch`
2. 
```
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
```
3. `sudo zypper --non-interactive install auditbeat filebeat packetbeat curl`

### Alpine (apk package manager)
1. `apk update && apk add curl wget`
2. `curl -O -L  https://github.com/ufsit/shreksophone1/raw/refs/heads/main/alpine-beats.tar.gz`
3. `tar zxf alpine-beats.tar.gz && rm alpine-beat.tar.gz`
4. **For every beat (auditbeat, filebeat, packetbeat)** complete the following steps:
    1. `mv <beat> /usr/bin`
    2. `curl -L -O https://artifacts.elastic.co/downloads/beats/<beat>/<beat>-8.19.6-linux-x86_64.tar.gz`
    3. `tar xzf <beat>-8.19.6-linux-x86_64.tar.gz && rm <beat>-8.19.6-linux-x86_64.tar.gz`
    4. `mv <beat>-8.19.6-linux-x86_64 /etc/<beat>`
    5. `rm /etc/<beat>/<beat>`
    6. `sed -i "s/\${path.config}/\/etc\/<beat>/g" /etc/<beat>/<beat>.yml`
    7. Add our open-rc service template for every beat into `/etc/init.d/<beat>`
    8. `chmod +x /etc/init.d/<beat>`
    9. `rc-update add <beat> default`
5. Remove lines 50-77 from the auditbeat.yml config file
6. Whenever you see `systemctl enable --now <beat>` later, replace it with `service <beat> start`.


## Configuring
Run this command to get an api key[^7]:
```
curl -k -X POST -u elastic:<password> "https://<server_ip>:9200/_security/api_key?pretty" -H 'Content-Type: application/json' -d'
{
  "name": "filebeat_host001",
  "role_descriptors": {
    "filebeat_writer": {
      "cluster": ["monitor", "read_ilm", "read_pipeline"],
      "index": [
        {
          "names": ["filebeat-*", "auditbeat-*", packetbeat-*"],
          "privileges": ["view_index_metadata", "create_doc", "auto_configure"]
        }
      ]
    }
  }
}
'
```
The api key you want to save for later is "id:key"
### Auditbeat [^2]
1. Edit `/etc/auditbeat/auditbeat.yml` and find the section `output.elasticsearch:` and replace it with:
```
output.elasticsearch:
  hosts: ["https://<server_ip>:9200"]
  preset: balanced
  api_key: "<api_key>"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "<ca_fingerprint>"
```
2. Place this at the end of `/etc/auditbeat/auditbeat.yml` to filter out audit logs created by the beats:
```
processors:
  - drop_event:
      when:
        or:
          - and:
            - equals:
                destination.ip: '192.168.1.90'
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
              destination.ip 127.0.0.1
          - equals:
              destination.ip: 127.0.0.53
```
3. Run `sudo auditbeat test output` to test our configurations
4. Place our auditd rules into `/etc/auditbeat/audit.rules.d/rules.conf` [^3]
5. `sudo systemctl daemon-reload && sudo systemctl enable auditbeat --now`
6. Run `sudo auditbeat show audit-rules` to make sure the rules were loaded properly
7. If you don't see any rules run `sudo systemctl restart auditbeat` and check again

**TODO: Add security rules for alerting and detection**
### Filebeat [^4]
1. Repeat step 2 from Auditbeat but edit `/etc/filebeat/filebeat.yml` this time
2. Run `sudo filebeat modules list` to check for the supported services
3. Run `sudo filebeat modules enable <service_module>` for each service on the machine
4. Edit the corresponding module file at `/etc/filebeat/modules.d/<service_module>.yml` and enable the logs you want
5. If there is an unsupported service, edit `/etc/filebeat/filebeat.yml` and at `paths:` under `filebeat.inputs:` add the log path for the service to monitor
6. Run `sudo filebeat test output` and `sudo filebeat test config` to make sure everything is valid
7. `sudo systemctl daemon-reload && sudo systemctl enable filebeat --now`

**Service logs are now forwarded to the ELK server**
### Packetbeat[^5]
1. Repeat step 2 from Auditbeat in the file `/etc/packetbeat/packetbeat.yml` and don't touch the `pipeline` variable
2. Edit the ports as needed in `/etc/packetbeat/packetbeat.yml` (Not necessary if everything is using the standard port)
3. Run `sudo packetbeat devices` and take note of the interface you want to monitor
4. Modify this line in `/etc/packetbeat/packetbeat.yml`: `packetbeat.interfaces.device: <interface name or number>` to monitor the correct interface
5. Edit `/etc/packetbeat/packetbeat.yml` and add the following lines [^6]
```
packetbeat.interfaces.type: af_packet
processors:
  - drop_event:
      when:
        or:
          - not:
              has_fields: ['source.ip', 'destination.ip']
          - and:
            - equals:
                destination.ip: 'server_ip'
            - equals:
                destination.port: 9200
          - and:
            - equals:
                destination.ip: 'ff02::2'
            - equals:
                network.transport: 'ipv6-icmp'
```
6. Run `sudo packetbeat test output` and `sudo packetbeat test config` to make sure everything works properly
7. `sudo systemctl daemon-reload && systemctl enable packetbeat --now`
8. In the dashboard go to Stack Management -> Data Views and check if `packetbeat-*` exists. If it does, you are done
9. Otherwise, click Create data view and give it the name and index pattern `packetbeat-*` and click save
**TODO: Look into alerting on specific packet patterns**

**TODO: Figure out setting up and configuring on Windows/Other Linux-like systems**

# References
[^1]: https://www.elastic.co/docs/reference/beats/auditbeat/setup-repositories
[^2]: https://www.elastic.co/guide/en/beats/auditbeat/8.19/auditbeat-installation-configuration.html
[^3]: https://www.elastic.co/docs/reference/beats/auditbeat/auditbeat-module-auditd
[^4]: https://www.elastic.co/guide/en/beats/filebeat/8.19/filebeat-installation-configuration.html
[^5]: https://www.elastic.co/guide/en/beats/packetbeat/8.19/packetbeat-installation-configuration.html
[^6]: https://www.elastic.co/guide/en/beats/packetbeat/8.19/defining-processors.html
[^7]: https://www.elastic.co/guide/en/beats/filebeat/8.19/beats-api-keys.html
