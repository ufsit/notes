# firewalld
* `--permanent` - flag added for changes to persist after reboot; not done by default to test changes
  * does not get applied automatically --> needs a reload
  * commands that are run without this flag get applied automatically
* Status
  * `sudo firewall-cmd --get-active-zones`
  * `sudo firewall-cmd --get-default-zone`
  * `sudo firewall-cmd --list-all-zones`
  * `sudo firewall-cmd --list-all --zone=[ZONE_NAME]`
  * `sudo firewall-cmd --list-services`
  * `sudo firewall-cmd --zone=public --get-target --permanent`    
* Reload configurations
  * `sudo firewall-cmd --reload`
* Assign interface to a zone
  * `sudo firewall-cmd --change-interface=[INTERFACE] --zone=[TARGET_FIREWALL_ZONE]`
* IPv4 Forwarding/NAT Forwarding/Masquerading
  * `sudo firewall-cmd --zone=[TARGET_ZONE] --[add|remove]-masquerade`
  * this zone will be able to _receive_ requests from other networks to it and pass it along on this network

## What is this "masquerading"?
* Enabling masquerading on Zone A allows traffic from other zones to be translated onto Zone A's network; 
  * **not the other way around**: traffic going into Zone A won't be translated to other zones.
* generally, masquerading is applied to the "Public" zone, so that other internal zones can access the Internet, but not external traffic can see the networks on the internal zones, only the networks exposed on the "Public" zone
  * To allow traffic incoming from the Public zone onto internal zones, you must setup Port Forwarding

## Port Forwarding
  * `sudo firewall-cmd --zone=[TARGET_ZONE] --[add|remove]-forward-port=port=##:proto=[TARGET_PROTOCOL]:toport=**:toaddr=[TARGET_IP_ADDRESS]`
    * port forwarding on a zone; if a packet arrives to TARGET_ZONE asking for port `##` on a certain protocol, redirect that packet to port `**` on TARGET_IP_ADDRESS
    * removing requires to rewrite the entire rule with `remove` keyword
* Add/Remove a port
  * `sudo firewall-cmd --zone=[TARGET_ZONE] --[add|remove]-port=[PORT]/[PROTO]`
* Add/Remove a service
  * `sudo firewall-cmd --zone=[TARGET_ZONE] --[add|remove]-service=[SERVICE]`
  * these are the services that are enabled in the router that the networks on the specified zone can access

**Example**
```
sudo firewall-cmd --zone=external --add-forward-port=port=80:proto=tcp:toport=80:toaddr=192.168.<team_number>.2 --permanent
```

* Remember to run `firewall-cmd --reload` to apply the rule.
* Now that we have configured port-forwarding, external network traffic can reach our internal web server, but __not the other way around__...



## Custom
* `sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" connection state="ESTABLISHED,RELATED" accept'`
  * if there is a connection on an allowed port, allow that same connection to leave on whatever port they want


## Note
* If a service is enabled on the zone and there is a port-forward rule for the same service that works on the same protocol, the port-forward takes precedence 
  * i.e. on `external` zone, `services` lists ssh, and there is a port-forward rule that forwards port 22. 
    * If an ssh request comes to the router, the port-forward rule will take precedence and ssh will connect to the target specified on the port-forward rule, not the router.
  * if there is a conflict, consider modifying the ssh port on the router or the port-forwarding 