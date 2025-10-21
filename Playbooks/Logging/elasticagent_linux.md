# Playbook for setting up Log forwarding
Work in progress...

Will eventually include all relevant operating systems
## Script
Currently we have a script that works on Ubuntu 16 and up

You can find the script [here](/Tools/SIEM/linux_agent.sh)

## Debian-Like
Some initial setup (skip if on the elastic server)[^1]
1. `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg`
2. 
```
sudo apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update
```
3. Run this command to get an api key[^7]:
```
curl -k -X POST -u elastic:<password> "https://<server_ip>:9200/_security/api_key?pretty" -H 'Content-Type: application/json' -d'
{
  "name": "filebeat_host001",
  "role_descriptors": {
    "filebeat_writer": {
      "cluster": ["monitor", "read_ilm", "read_pipeline"],
      "index": [
        {
          "names": ["filebeat-*", "auditbeat", packetbeat"],
          "privileges": ["view_index_metadata", "create_doc", "auto_configure"]
        }
      ]
    }
  }
}
'
```
### Auditbeat [^2]
1. `sudo apt-get install auditbeat`
2. Edit `/etc/auditbeat/auditbeat.yml` and find the section `output.elasticsearch:` and replace it with:
```
output.elasticsearch:
  hosts: ["https://<server_ip>:9200"]
  preset: balanced
  api_key: "<api_key>"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "<ca_fingerprint>"
```
3. Run `sudo auditbeat test output` to test our configurations
4. Place our auditd rules into `/etc/auditbeat/audit.rules.d/rules.conf` [^3]
5. `sudo systemctl daemon-reload && sudo systemctl enable auditbeat --now`
6. Run `sudo auditbeat show audit-rules` to make sure the rules were loaded properly
7. If you don't see any rules run `sudo systemctl restart auditbeat` and check again

**TODO: Add security rules for alerting and detection**
### Filebeat [^4]
1. `sudo apt-get install filebeat`
2. Repeat step 2 from Auditbeat but edit `/etc/filebeat/filebeat.yml` this time
3. Run `sudo filebeat modules list` to check for the supported services
4. Run `sudo filebeat modules enable <service_module>` for each service on the machine
5. Edit the corresponding module file at `/etc/filebeat/modules.d/<service_module>.yml` and enable the logs you want
6. If there is an unsupported service, edit `/etc/filebeat/filebeat.yml` and at `paths:` under `filebeat.inputs:` add the log path for the service to monitor
7. Run `sudo filebeat test output` and `sudo filebeat test config` to make sure everything is valid
8. `sudo systemctl daemon-reload && sudo systemctl enable filebeat --now`
**Service logs are now forwarded to the ELK server**
### Packetbeat[^5]
1. `sudo apt-get install packetbeat`
2. Repeat step 2 from Auditbeat in the file `/etc/packetbeat/packetbeat.yml` and don't touch the `pipeline` variable
3. Edit the ports as needed in `/etc/packetbeat/packetbeat.yml` (Not necessary if everything is using the standard port)
4. Run `sudo packetbeat devices` and take note of the interface you want to monitor
5. Modify this line in `/etc/packetbeat/packetbeat.yml`: `packetbeat.interfaces.device: <interface name or number>` to monitor the correct interface
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
