# START
1. Run `sudo filebeat modules list` and see if the service is listed under "Disabled:"
2. If it is listed, continue. Otherwise, jump to Manual Setup
3. Run `sudo filebeat modules enable <service>`
4. Open the file `/etc/filebeat/modules.d/<service>.yml` and enable all logs
5. If the logs are not forwarding, you may have to specify the direct path under each section in the file as the `var.paths` variable
6. To make sure everything is commited, run `sudo systemctl restart filebeat`

# Manual Setup
1. Open the file `/etc/filebeat/filebeat.yml` and go to the section under `- type: filestream`.
2. Make sure that enabled is true and add the path to the logs as:
```
  paths:
  - /example/path/log
  - /another/strange/log
```
3. Run `sudo filebeat test config` to make sure there are no yaml issues
4. Run `sudo systemctl restart filebeat` to load the configuration
