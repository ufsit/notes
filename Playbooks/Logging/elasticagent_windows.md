# Elastic agent setup for Windows  
**Install Sysmon before doing this if possible**  
If Sysmon was not installed using the script attempt to run this before getting the zip  
```
Import-Module BitsTransfer
```  
1.
```
Start-BitsTransfer -Source https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.19.5-windows-x86_64.zip -Destination "C:\Program Files\winbeat.zip"
```  
2. Extract the zip and make sure the folder with all the winlogbeat stuff is named *Winlogbeat* (case sensative) in Program Files
3. 
```
   .\install-service-winlogbeat.ps1
```
4. 
```
   (Get-Content winlogbeat.yml -Raw) -replace "`n","`r`n" | Set-Content winlogbeat_fixed.yml
```  
   Run this to better format the yml file if it is not formatted properly then delete the original and rename this one to winlogbeat.yml once you make sure it's formatted correctly
5. Run these commands to get an api key:
```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) { return true; }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy;
$username = "elastic";

$password = ConvertTo-SecureString '<password>' -AsPlainText -Force;

$credential = New-Object System.Management.Automation.PSCredential($username, $password);

$response = Invoke-WebRequest -Uri "https://<server_ip>:9200/_security/api_key?pretty" -Method Post -Credential $credential -ContentType "application/json" -Body "`n{`n  `"name`": `"<hostname>`", `n  `"role_descriptors`": {`n    `"winlogbeat_writer`": { `n      `"cluster`": [`"monitor`", `"read_ilm`", `"read_pipeline`"],`n      `"index`": [`n        {`n          `"names`": [`"winlogbeat-*`"],`n          `"privileges`": [`"view_index_metadata`", `"create_doc`", `"auto_configure`"]`n        }`n      ]`n    }`n  }`n}`n" | convertfrom-json;

$response.id + ":" + $response.api_key
```
5. In winlogbeat.yml under **output.elasticsearch:** 
```
hosts: [https://{host ip}:9200]
api_key: <key from above>
``` 
6. Still in the yml add under step 5
```
   ssl:
     enabled: true
     ca_trusted_fingerprint: "{fingerprint given by server controller}"
```
7. Make sure under *winbeat.event_logs* that Sysmon/Operational and GroupPolicy/Operational is here as a - name: param
8. Under *Kibana* uncomment hosts and change to *hosts: "[server ip]:5601"*
9. Test the yml with `.\winlogbeat.exe test config -c .\winlogbeat.yml -e`
10. `.\winlogbeat.exe setup -e`
11. `Start-Service winlogbeat`
