# Playbook for setting up Log forwarding
Work in progress...

Will eventually include all relevant operating systems
## Debian-Like
Some initial setup (skip if on the elastic server)
1. `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg`
2. `sudo apt-get install apt-transport-https` 
3. `echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list`
4. `sudo apt-get update`
### Auditbeat
1. `sudo apt-get install auditbeat`
2. Log into elastic dashboard and go to Stack Management -> API Keys -> Create API Key
3. Give the API key the name `<hostname>_key` and click create API
4. When the key pops up, click on the dropdown and select Beats. The key should look something like `sIqr35kBnoxDjXVkcovB:34eROMe-vxfMoy6iTE6Fiw` **Save this somewhere safe. We will use this for every beat on the machine**
5. Edit `/etc/auditbeat/auditbeat.yml` and find the section `output.elasticsearch:` and replace it with:
```
output.elasticsearch:
  hosts: ["https://<server_ip>:9200"]
  preset: balanced
  api_key: "<api_key>"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "<ca_fingerprint>"
```
6. Run `sudo auditbeat test output` to test our configurations
7. Place our auditd rules into `/etc/auditbeat/audit.rules.d/rules.conf`
8. `sudo systemctl enable auditbeat --now`
9. Run `sudo auditbeat show audit-rules` to make sure the rules were loaded properly
**TODO: Add security rules for alerting and detection**
### Filebeat
1. `sudo apt-get install filebeat`
2. Repeat step 5 from Auditbeat but edit `/etc/filebeat/filebeat.yml` this time
3. Run `sudo filebeat modules list` to check for the supported services
4. Run `sudo filebeat modules enable <service_module>` for each service on the machine
5. Edit the corresponding module file at `/etc/filebeat/modules.d/<service_module>.yml` and enable the logs you want
6. If there is an unsupported service, edit `/etc/filebeat/filebeat.yml` and at `paths:` under `filebeat.inputs:` add the log path for the service to monitor
7. Run `sudo filebeat test output` and `sudo filebeat test config` to make sure everything is valid
8. `sudo systemctl enable --now filebeat`
**Service logs are now forwarded to the ELK server**
### Packetbeat
**TODO: Test setting up packetbeat and look at configurations**

**TODO: Figure out setting up and configuring on Windows/Other Linux-like systems**
