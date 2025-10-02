# Components
## **Targets**
* a decision of what to do with a packet:
  * ACCEPT : Pass the packet trough the firewall
  * DROP : discards the packet without informing the sender
  * REJECT : discards the packet and returns an error response to the sender
  * LOG : records packet information into a log file
  * SNAT : (Source Network Address Translation) - alters the packet's source address
  * DNAT : (Destination Network Address Translation) - Changes the packet's destination address
  * MASQUERADE : ALters a packet's source address for dynamically assigned IPs
## **Rules**
* a statement that defines the conditions for matching a packet, then sent to target
* Every rule is part of a chain and contains specific criteria, such as source or destination IP addresses, port numbers, or protocols
* Any packet matching a rule's conditions is forwarded to a target that determines what happens to the packet 
## **Chains**
* a string of rules; when a packet is received, iptables finds the appropriate table and filters it through the rule chain until it finds a match
  * **INPUT** - handles incoming packets whose destination is a local application or service. 
    * The chain is in the **Filter** and **Mangle** tables
  * **OUTPUT** - Manages outgoing packets generated on a local **application** or service. 
    * All tables contain this chain.
  * **PREROUTING** - Alters packets before they are routed. The alteration happens before a routing decision. 
    * The **NAT**, **Mangle**, and **Raw** tables contain this chain.
  * **POSTROUTING** - alters packets after they are routed. The alteration happens after a routing decision. 
    * The **NAT** and **MANGLE** tables contain this chain.
## **Tables** 
* Files that group similar rules; consists of several rule chains
* There are four default tables:
  * **Filter** - default packet filtering table. It acts as a gatekeeper that decides which packets enter and leave a network
    * INPUT, OUTPUT, FORWARD
  * **Network Address Translation (NAT)** - contains NAT rules for routing packets to remote networks. It is used for packets that require alterations
    * OUTPUT, PREROUTING, POSTROUTING
  * **Mangle** - adjusts the IP header properties of packets
    * INPUT, OUTPUT, FORWARD, PREROUTING, POSTROUTING
  * **Raw** - Exempts packets from connection tracking
    * OUTPUT, PREROUTING
# Usage
[Link](https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules)
* `iptables [options] [chain] [chain_criteria] -j [target]`
* `sudo iptables -L --list-numbers` : list rules
* `sudo iptables -D <#> <chain>` : delete a rule
* `sudo iptables -F <chain>` : flush all rules on a chain
## Port usage
* `sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT`
  * allow HTTP web traffic
* `sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT`
  * allow only incoming SSH traffic
* `sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT`
  * allow HTTPS traffic
* `sudo iptables -A INPUT -p tcp --dport <port> -j ACCEPT`
  * allow general port
* `sudo iptables -A INPUT -p tcp --dport <port_start:port_end> -j ACCEPT`
  * allow range of ports
## IP Address usage
* `sudo iptables -A INPUT -s [IP_ADDRESS] -j ACCEPT`
  * allow all traffic from an IP address
* `sudo iptables -A INPUT -s [IP_ADDRESS] -j DROP`
  * drop traffic from an IP address 