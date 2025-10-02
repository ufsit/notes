# networking
* older Debian
* `systemctl status networking`
* `/etc/network/interfaces`
```
auto <INTERFACE>
iface <INTERFACE> inet static        # static/dhcp
    address <IP_ADDRESS>
    netmask <IP_ADDRESS>
    gateway <IP_ADDRESS>
    dns-domain <DNS-DOMAIN>
    dns-nameservers <IP_ADDRESS> <IP_ADDRESS> <IP_ADDRESS>
```
* `systemctl restart networking`

# netplan
* typically in Ubuntu
* `/etc/netplan/##-plan_name.yaml`
  * must have 600 permissions
```
network:
  version: 2
  ethernets:
    <INTERFACE>:                  # desired interface
      dhcp4: false                # false for static, optional
      dhcp6: false                # false for static, optional
      addresses:
      - <ip_address>/<cidr>
      routes:
      - to: default
        via: <default_gateway_ip_address>
      nameservers:
        addresses: <ip_address_1, ip_address_2, ...>  
```
* sudo netplan apply

# network
* typically in CentOS
* `systemctl status network`
* `/etc/sysconfig/network-scripts/ifcfg-<interface>`
```
BOOTPROTO=static
ONBOOT=yes
IPADDR=<IP_ADDRESS>
NETMASK=<NETMASK>
ZONE=<FIREWALL_ZONE_NAME>   # optional
GATEWAY=<IP_ADDRESS>        # if needed
```
* `systemctl status network`

# NetworkManager
* typically in RHEL-based distros
* `systemctl status NetworkManager`
```
nmcli connection show
nmcli con mod <INTERFACE> ipv4.address <IP/CIDR>
nmcli con mod <INTERFACE> ipv4.gateway <IP>
nmcli con mod <INTERFACE> ipv4.dns <IP1 IP2 ...>
nmcli con mod <INTERFACE> ipv4.method manual                # static
nmcli con down <INTERFACE> && nmcli con up <INTERFACE>
```
* `systemctl restart NetworkManager`
* ALTERNATE: `nmtui` for a TUI configuration

