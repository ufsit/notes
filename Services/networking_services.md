- [Networking](#networking)
  - [networking](#networking-1)
  - [netplan](#netplan)
  - [network](#network)
  - [NetworkManager](#networkmanager)
  - [systemd-networkd](#systemd-networkd)
  - [miscellaneous](#miscellaneous)

# Networking
* The following are a few network managers and common configurations for each
* After every configuration change, you should restart the service for the changes to take effect
* In principle, any one of these network managers can be made to work in any distro, so it's best to check which of the following network managers your system actually installed
* NOTE: in the following examples, these `<>` symbols highlight the placeholder, they are never written unless specified; CPAITAL letters mean a placeholder name, lowercase contents represent examples
## networking
* Check if you are running this service: `systemctl status networking`
* Config File: `/etc/network/interfaces`
* For a static address
```
auto eth0
iface eth0 inet static        # static/dhcp
    address <IP_ADDRESS>
    netmask <IP_ADDRESS>
    gateway <IP_ADDRESS>
    dns-domain <DNS-DOMAIN>
    dns-nameservers <IP_ADDRESS> <IP_ADDRESS> <IP_ADDRESS>
```
* For a dynamic address
```
auto eth0
iface eth0 dhcp
```
* `sudo systemctl restart networking`
* if the `resolvconf` package is installed, **_DO NOT_** edit `resolv.conf` directly and set the nameserver as below
* Typical in older Debian

## netplan
* To check if you are running this service: check if `/etc/netplan` exists
* Config Files: `/etc/netplan/*`
* These files should have 600 permissions
* Example config file: `01-main.yaml`
  * The main restriction for the naming scheme is to have two digits followed by a dash `##-`, and ending with `.yaml` (`.yml` breaks netplan)
  * The numbering scheme represents the precedence, numbers closer to `01` will take precendence
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
* `sudo netplan apply`
* Typicaly in Ubuntu
## network
* Check if you are running this service: `systemctl status network`
* `/etc/sysconfig/network-scripts/`
* Edit/create a file with the following scheme: `ifcfg-<interface>` where the interface matches an interface from `ip a`
* Add/Edit the following as needed: (for a static address)
```
TYPE=Ethernet
BOOTPROTO=static
ONBOOT=yes
IPADDR=<IP_ADDRESS>
NETMASK=<NETMASK>
ZONE=<FIREWALLD_ZONE_NAME>   # optional, when firewalld is enabled
GATEWAY=<IP_ADDRESS>        # if needed
```
* Add/Edit the following as needed: (for a static address) <!-- TODO: fact check the following-->
```
TYPE=Ethernet
BOOTPROTO=dhcp
ONBOOT=yes
ZONE=<FIREWALL_ZONE_NAME>   # optional
GATEWAY=<IP_ADDRESS>        # if needed
```
* `sudo systemctl restart network`
* Typical in CentOS

## NetworkManager
* Check if you are running this service: `systemctl status NetworkManager`
```
sudo systemctl <start|stop|restart> NetworkManager
nmcli connection show
nmcli con mod <INTERFACE> ipv4.address <IP/CIDR>
nmcli con mod <INTERFACE> ipv4.gateway <IP>
nmcli con mod <INTERFACE> ipv4.dns <IP1 IP2 ...>
nmcli con mod <INTERFACE> ipv4.method manual                # static
nmcli con down <INTERFACE> && nmcli con up <INTERFACE>
```
* `systemctl restart NetworkManager`<br><br>
* Can install `nmtui` for a text-based gui (TUI)
* default on CentOS server, can also be found in RHEL-based distros

## systemd-networkd
* Check if you are running this service: `systemctl status systemd-networkd`
* `ip link show dev <INTERFACE>`
* `ip link set <INTERFACE> <up|down>`
* `networkctl list`
* edit files as per this [guide](https://wiki.archlinux.org/title/Systemd-networkd#Wired_adapter_using_a_static_IP)
* `systemctl reload systemd-networkd`

* used by Arch

## miscellaneous
* `sudo ip addr add [IP_ADDRESS]/[CIDR] dev [INTERFACE]`
  * this will add a new static IP address to an interface _temporarily_; will not persist after a reboot
* `sudo ip addr flush dev [INTERFACE]`
  * will remove all IP Addresses for that interface
  * should restart the networking service
