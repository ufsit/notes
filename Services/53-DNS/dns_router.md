# For DNS Request Across the Router
## Configure External Kali like the Internal was
Add nameserver to this machine as the router:
`sudo nano /etc/resolv.conf`
then add `nameserver <external routerip>`
## In CentOS Router
1. DNS requests forwarding must be enabled by running command:
`sudo firewall-cmd --zone=external --permanent --add-forward-port=port53:proto=udp:toport53:toaddr=<dnsserverip>`
2. `sudo firewall-cmd -r-reload`
   - _note: run `sudo firewall-cmd --list-all --zone=external` to check firewalls activities_
