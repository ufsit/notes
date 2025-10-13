# Playbook for setting up Elastic
Work in progress...  
Will be the full setup for Elastic logging  
## Elasticsearch
1. ```wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg```  
2. ```sudo apt-get install apt-transport-https```  
3. ```echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list```  
4. ```sudo apt-get update && sudo apt-get install elasticsearch```  
**Make sure to save the password this spits out**  
5. 
```sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```
## Kibana
Assuming you did the first 4 steps of Elasticsearch setup  
```sudo apt-get install kibana```  
```
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana
```
The UI can be found at ```localhost:5601```  
