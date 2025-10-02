# Status
* `/interface print` - to show information on interfaces
* `/ip address print` - to show assigned ip addresses
* `/ip route print` - shows routes, whether gateway are correctly set
* `/ip service print` - shows services running on the router
* `/ping [IP_ADDRESS]` 

# Manage IP Address
* `/ip address add address=[IP_ADDRESS/CIDR] interface=[TARGET_INTERFACE]` - assign ip address to an available interface from the previous command
  * `/ip address remove #[#]` - will remove an address, numbered after `/ip address print`
  * `/ip address set interface=[INTERFACE_NAME] address=[IP_ADDRESS/CIDR]` - modify 

# Manage Gateway
* `/ip route add gateway=[GATEWAY_IP]`
  * `ip route remove #[#]` - to remove a gateway, numbers from `ip route print`

# Bridges
* To add a bridge and add an interface to it
  * `/interface bridge add name=bridge1`
  * `/interface bridge port add interface=ether2 bridge=bridge1`

# Port Forwarding
* For Port Forwarding, use the web page for it, usually runs on port 8080
  * `Bridge all LAN Ports` - this is IPv4 forwarding, I think
  * `NAT` - should also be checked
    * apply both of these on internal interface
# NAT (SNAT)
* `/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade`
* `/ip firewall nat print`
* `/ip firewall filter remove [index]`


# Tasks
## Configure the router from scratch
```
/user set [find name=admin] password=<newpassword>
/interface print
/ip address add=<ip/cidr> interface=<interface>     # external
/ip address add=<ip/cidr> interface=<interface>     # internal
/ip route add gateway=<gateway_ip>
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
```

## MicroTik Hardening
[Link](https://help.mikrotik.com/docs/spaces/ROS/pages/328353/Securing+your+router)
### Notes
* If you want to add more interfaces to the router, add a new Network Interface Card (NIC) to the vm through the hypervisor.