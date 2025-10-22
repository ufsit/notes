# Elastic agent setup for Windows  
**Install Sysmon before doing this if possible**
1.
```
Start-BitsTransfer -Source https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.19.5-windows-x86_64.zip -Destination "C:\Program Files\winbeat.zip"
```  
2. Extract the zip
3. ```
   .\install-service-winlogbeat.ps1
   ```
4. ```
   (Get-Content winlogbeat.yml -Raw) -replace "`n","`r`n" | Set-Content winlogbeat_fixed.yml
   ```  
   Run this to better format the yml file if it is not formatted properly
5. In winlogbeat.yml under **output.elasticsearch:** ```hosts: [https://{host ip}:59200]``` and until API key can be figured out set username: to "elastic" and password: to "{password given by server controller}"
6. Still in the yml add under step 5
   ```
   ssl:
     enabled: true
     ca_trusted_fingerprint: "{fingerprint given by server controller}"
   ```
7. Make sure under *winbeat.event_logs* that Sysmon/Operational is here as a - name: param
8. Test the yml with ```.\winlogbeat.exe test config -c .\winlogbeat.yml -e```
9. ```.\winlogbeat.exe setup -e```
10. ```Start-Service winlogbeat```
