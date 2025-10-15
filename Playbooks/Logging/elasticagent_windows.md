# Elastic agent setup for Windows  
1. 
```
# PowerShell 5.0+
wget https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.19.5-windows-x86_64.zip -OutFile elastic-agent-8.19.5-windows-x86_64.zip
Expand-Archive .\elastic-agent-8.19.5-windows-x86_64.zip
```
2. In the elastic-agent.yml policy file, under outputs, specify an API key or user credentials for the Elastic Agent to access Elasticsearch. For example:
```
outputs:
  default:
    type: elasticsearch
    hosts:
      - 'https://serverip:9200'
    api_key: [your api]
    ssl:
      enabled: true
      ca_trusted_fingerprint: [fingerprint from setup]
```  
3. 
```
.\elastic-agent.exe install
```
