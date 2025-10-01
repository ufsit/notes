# ufw (Ubuntu)
* Check status
  * `sudo ufw status`
* show active rules
  * `sudo ufw show added`
* Block all INCOMING connections that aren't scored
  * `sudo ufw default deny incoming`
* Allow scored services
  * `sudo ufw allow [PORT]/[tcp/udp]`
* Start firewall
  * `sudo ufw enable`<br><br>
* for reference
  * `sudo ufw [deny|allow] [in|out] [PORT]/[tcp|udp]`

# firewalld (CentOS/RedHat)
> Pay attention to the Public zone

* Check status
  * `sudo firewall-cmd --state`
* show active rules
  * `sudo firewall-cmd --list-all-zones`
* Block Incoming Ports
  * `sudo firewall-cmd --zone=public --add-port=[PORT]/[tcp|udp] --permanent --remove-port=[PORT]/[tcp|udp]`
* Allow Incoming Port
  * `sudo firewall-cmd --zone=public --add-port=[PORT]/[tcp|udp] --permanent`

# iptables (All Linux)
* Check status
  * `sudo systemctl status iptables`
* show active rules
  * `sudo iptables -L [INPUT|OUTPUT] -v -n`
* Block/Allow an Incoming/Outgoing port
  * `sudo iptables -A [INPUT|OUTPUT] -p [tcp|udp] --dport [PORT] -j [DROP|ACCEPT]`
* Start firewall
  * `sudo systemctl start iptables`