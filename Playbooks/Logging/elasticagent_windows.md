# Elastic agent setup for Windows  
**Install Sysmon before doing this if possible**
1.
```
Start-BitsTransfer -Source https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.19.5-windows-x86_64.zip -Destination "C:\Program Files\winbeat.zip"
```  
2. Extract the zip and make sure the folder with all the winlogbeat stuff is named *Winlogbeat* (case sensative) in Program Files
3. ```
   .\install-service-winlogbeat.ps1
   ```
4. ```
   (Get-Content winlogbeat.yml -Raw) -replace "`n","`r`n" | Set-Content winlogbeat_fixed.yml
   ```  
   Run this to better format the yml file if it is not formatted properly then delete the original and rename this one to winlogbeat.yml once you make sure it's formatted correctly
5. In winlogbeat.yml under **output.elasticsearch:** ```hosts: [https://{host ip}:9200]``` and until API key can be figured out set username: to "elastic" and password: to "{password given by server controller}"
6. Still in the yml add under step 5
   ```
   ssl:
     enabled: true
     ca_trusted_fingerprint: "{fingerprint given by server controller}"
   ```
7. Make sure under *winbeat.event_logs* that Sysmon/Operational is here as a - name: param
8. Under *Kibana* uncomment hosts and change to *hosts: "[server ip]:5601"*
9. Test the yml with ```.\winlogbeat.exe test config -c .\winlogbeat.yml -e```
10. ```.\winlogbeat.exe setup -e```
11. ```Start-Service winlogbeat```
