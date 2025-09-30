# **Ubuntu Machine as DNS server on the local network**
1. Edit the `etc/resolv.conf` file on internal Kali Device: use `sudo nano /etc/resolv.conf`
2. Add the `nameserver 192.168.<team_number>.2` line at the end
## Configuring the Server to Resolve the Scoreboard
**On the Server (Ubuntu Machine):** 'cd /etc/bind'
1. run `sudo nano zones/forward.<domainname>`
  - **_change serial number_**
2. Below existing rules, write `<subdomainname>     IN A     <scoreboard ip address>`
`sudo systemctl restart named`
4. use `nslookup <subdomain.domain>`
  - Should return: ```Name:   <subdomain.domain>
                      Address: <scoreboard ip address>```
## Reverse Lookups
1. (still in `/etc/bind` run `sudo nano named.conf.default-zones`
2. New Entry:
```
zone <IP address (e.g. "20.172 in-addr.arpa") IN {
      type master;
      file "/etc/bind/zones/reverse.<domainname>";
      allow-update { none; };
 };
```

_For Reverse Lookup File_

3. run `sudo nano /etc/bind/zones/reverse.<domainname>`
  - *_change serial number_*

new entry `subdhost info (e.g. 1.0)  IN PTR <subdomain.domainname>`

4. run `sudo systemctl restart named`

5. confirm with `nslookup <subdomain IP>`
