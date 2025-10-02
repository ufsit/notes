# DNS
* Domain Name System
* The service responsible for translating hostnames (google.com) to IP addresses


## A Distributed, Hierarchical Database
- no single DNS server has all the mappings for all the hostnames in existence; rather, they are distributed across a hierarchy of DNS servers, some containing the actual mapping, others pointing to other DNS servers 

- roughly, three classes:
1. **Root** servers
	- more than 1000 around the world,
	- copies of 13 different root servers, managed by 12 organizations
	- provide IPs of the TLD servers
2. **Top-Level Domain (TLD)** servers
	- the .com, .org, .net, .edu, .uk, ...
	- provide IP addresses for authoritative DNS servers
3. **Authoritative** servers
	- every organization with publicly accessible hosts must provide accessible DNS records 
	- an organization's authoritative DNS server houses these records
	- an organization can pay to host own server or pay a third party

- **Local server** 
	- does not strictly belong to the hierarchy of servers,
	- each ISP (residential or institutional) has a local DNS server
	- act like proxies, managed by the ISP, for the actual DNS hierarchy

- In practice, TLD servers do not always have the address of the desired authoritative server
	- they may only know of intermediate TLD servers

- **recursive queries**: when the servers in the chain each ask the next server on the requester's behalf
- **iterative queries**: when a client asks a server, gets an answer, and the client asks the new server, and so on until it gets the answer
	- In practice, the first query to the local server is recursive, and the rest art typically iterative (can be hybrid)


## DNS Records and Messages
- DNS stores **resource records (RRs)**
- each DNS reply message carries one or more of these RRs
- Resource Records (RRs) $=$ (`Name`, `Value`, `Type`, `TTL`)
	- `TTL` - time to live of the record in cache
	- `Type=A` $\rightarrow$ `Name` is a hostname, `Value` is the IP address (IPv4)
	- `Type=AAAA` $\rightarrow$ `Name` is a hostname, `Value` is the IP address (IPv6)
	- `Type=NS` $\rightarrow$ `Name` is a domain (*foo.bar*), `Value` is the hostname of an authoritative server for the domain (NS=nameserver)
	- `Type=CNAME` $\rightarrow$ `Name` holds the aliased name of the Canonical NAME in `Value`
	- `Type=MX` $\rightarrow$ `Name` is the alias of a mail server, `Value` is the canonical name of the mail server
	- `Type=PTR` $\rightarrow$ `Name` contains the reversed IP address followed by `.in-addr.arpa`, `Value` contains the domain the address resolves to
- If a DNS server is authoritative for a hostname, the server contains the A record for the hostname
	- a non-authoritative server may have the same A-record in cache
- A non-authoritative server for a hostname will contain an NS record for the server that is authoritative for the hostname
	- it will also contain the A record this nameserver <br><br>
* `CNAME` records useful when running multiple services from a single IP address, like FTP and web
  * CNAME records can point `ftp.example.com` and `www.example.com` to the same IP address, allowing you to work with hostnames that are service specific point to the same server handling these services
  * if the address of the server ever changes, we only need to modify the one `A` record instead of many.
  * CNAME records only every point to another domain name, never directly to an IP address
* `MX` and `NS` records must never point to a `CNAME` alias

**Example**
```
NAME              TYPE    VALUE
-------------------------------------------
bar.example.com.  CNAME   foo.example.com.
foo.example.com.  A       192.0.2.23
```
  * when an A record lookup for `bar.example.com` is carried out, the resolver will see a CNAME record and restart the lookup for `foo.example.com` and will then return 192.0.2.23
  * Hence, it is said that `bar.example.com`. is an alias for the Canonical name (CNAME) `foo.example.com`
  
### Note
* `forward lookup` : domain to IP
* `reverse lookup` : IP to domain
* for machines that need to hop a router for DNS server, the external machine's "DNS server" address will be configured to be the router itself
  * the router will then port-forward that packet to the DNS server across the router

# DNS servers
## Bind
* Install:
  * `apt install bind9 bind9utils bind9-doc`
* Service
  * `bind9` or `named`; may be symlinked to each other
  * `sudo systemctl start named`
  * `sudo systemctl status named`
  * use `nslookup` to verify DNS server has been configured (try it on the web server you're trying to setup)
### Config (Debian)
  * `/etc/bind/*`
    * `db.empty` is an empty config file that can be used as a template; 
      * **MAKE SURE** to use `cp` instead of making it from scratch since `cp` preserves appropriate permissions
  * most of the work will be on `named.conf.default-zones`
  * For reverse lookups, only include the **network** part of the address, then reverse it
    * you will include a reverse lookup entry in `named.conf.default-zones` for every domain in a network
  * For forward lookups, you will make an entry in `named.conf.default-zones` for every domain
#### Example
* From NCAE Mini Hacks
* Suppose the Web server holds the address `192.168.201.2/24`; and that the machine's computer name is `sandbox-Ubuntu`
* We'll create the appropriate DNS records for this web server at that address
* **`/etc/bind/named.conf.default-zones`**
```
[---- FORWARD LOOKUP ----] # Title, don't actually write this
zone "ncaecybergames.org" IN {
  type master;
  file "/etc/bind/forward";           
  allow-update { none; };
};


[---- REVERSE LOOKUP ----] # Title, don't actually write this
zone "201.168.192.in-addr.arpa" IN {
  type master;
  file "/etc/bind/reverse";
  allow-update { none; };
};

```

* We will now create the records for forward lookups in `forward` and reverse lookups in `reverse`
* we specified to have these files in the `/etc/bind/` directory; this is not a hard requirement, these can be in a subdirectory as well; if you do, specify acoordingly the file paths in `named.conf.default-zones`
* To create the `forward` and `reverse` files, we will `cp db.empty` to preserve appropriate permissions<br><br>

**`db.empty`**
```
; BIND reverse data file for empty rfc1918 zone
;
; DO NOT EDIT THIS FILE - it is used for multiple zones.
; Instead, copy it, edit named.conf, and use that copy.
;
$TTL	86400
@	IN	SOA	localhost. root.localhost. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	NS	localhost.
```

**`forward`**
```
$TTL	86400
@	IN	SOA	ncaecybergames.org root (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	        NS	    sandbox-Ubuntu
www             IN A    192.168.201.2
sandbox-Ubuntu  IN A    192.168.201.2
```
* in the `SOA` line, replace `localhost.` with the desired domain `ncaecybergames.org`
* every time you make a change this file, add 1 to the `Serial` number
* in the `NS` line, replace `localhost.` with the host name (computer name) of the nameserver
* the following A-records configure subdomains
* With this config, we can resolve requests for: `ncaecybergames.org`, `www.ncacecybergames.org`, and `sandbox-Ubuntu.ncaecybergames.org`

**`reverse`**
```
$TTL	86400
@	IN	SOA	ncaecybergames.org. root (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	        NS	    sandbox-Ubuntu
2   IN PTR      www.ncaecybergames.org.
2   IN PTR      sandbox-Ubuntu.ncaecybergames.org.
```
* note the `.` at the end of the domains in `PTR` records; without these, the records break
* the address for these `PTR` records is the host part of the IP address for the target host
  * i.e. the web server is at `192.168.201.2/24`, so we only put the `2` here

<!-- TODO: Verify section 32. Additional Zones from file 00.TO-INTEGRATE -->

### Configure Clients
* modify the client's networking service to point to our DNS server for its nameserver
* Alternatively, append to `/etc/resolv.conf` directly (may break, ideally you should do this through the networking service)
  * `nameserver <dns_server_address>`

**For DNS Requests Across a Router**
  * Configure the external machine's nameserver address to be that  of the router
  * On the router, add a port-forward rule to forward incoming DNS requests to the router through to the DNS server on the other side of the router

**NCAE Example**
* **Configure External Kali like the Internal was**
  * edit `/etc/resolv.conf`
  * append `nameserver <external_router_ip>`
* **In CentOS Router**
  * DNS requests forwarding must be enabled by running command:
```
sudo firewall-cmd --zone=external --permanent --add-forward-port=port53:proto=udp:toport53:toaddr=<dnsserverip>
```
  * `sudo firewall-cmd --reload`
  * _note: run `sudo firewall-cmd --list-all --zone=external` to check firewalls activities_