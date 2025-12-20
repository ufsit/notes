# How to change ports for web-firewall (Linux)
**Apache HTTP Server**
```
/etc/apache2/ports.conf #(Debian/Ubuntu)
/etc/httpd/conf/httpd.conf #(RHEL/CentOS/Alma/Rocky)
```
```
Listen 80  -->  Listen <port_number>
<VirtualHost *:80>   -->  <VirtualHost *:<port_number>> #(Check virtual hosts if applicable)
```
```
sudo systemctl restart apache2   # Debian/Ubuntu
sudo systemctl restart httpd     # RHEL-based
ss -tulpn | grep apache
```
___________________________________________________________________________________________________________________
 **NGINX**
 ```
/etc/nginx/nginx.conf
/etc/nginx/sites-enabled/default
```
(usual locations)
```
server {                server {
    listen 80;  -->       listen <port_number>
}                       }
```
```
sudo nginx -t        #test first
sudo systemctl restart nginx
ss -tulpn | grep nginx
``` 
__________________________________________________________________________________________________________________
**Lighttpd**
```
/etc/lighttpd/lighttpd.conf
```
```
server.port = 80  -->  server.port = <port_number>
```
```
sudo systemctl restart lighttpd
```
__________________________________________________________________________________________________________________
**Caddy**
```
/etc/caddy/Caddyfile
```
```
:80 {                            :<port_number> {
    root * /var/www/html   -->        root * /var/www/html
}                                }
```
```
sudo systemctl restart caddy
```
__________________________________________________________________________________________________________________
**Apache Tomcat**
```
/conf/server.xml
```
```
<Connector port="80" protocol="HTTP/1.1"/>  -->  <Connector port="<port_number>" protocol="HTTP/1.1"/>
```
```
sudo systemctl restart tomcat
```
__________________________________________________________________________________________________________________
**Jellyfin**
```
/etc/jellyfin/system.xml
```
```
<PublicPort<8080>/PublicPort>   -->   <PublicPort><port_number></PublicPort>
<HttpServerPortNumber>8080</HttpServerPortNumber> --> <HttpServerPortNumber><port_number></HttpServerPortNumber>
```
```
sudo systemctl restart jellyfin
ss -tulpn | grep jellyfin
```
__________________________________________________________________________________________________________________
**Squid Proxy**
```
/etc/squid/squid.conf
/etc/squid3/squid.conf  #on older systems
```
```
http_port 80  -->  http_port <port_number>
```
```
sudo squid -k parse
sudo systemctl restart squid
ss -tulpn | grep squid
```
__________________________________________________________________________________________________________________
Feel free to add any more, obviously windows will be different, download location depends on how they installed :) **-Niklas**
