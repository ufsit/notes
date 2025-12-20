**How to change ports for web-firewall (Linux)** 
___________________________________________________________________________________________________________________
# Apache HTTP Server
/etc/apache2/ports.conf (Debian/Ubuntu)
/etc/httpd/conf/httpd.conf (RHEL/CentOS/Alma/Rocky)

Listen 80 --> Listen <port_number>
<VirtualHost *:80>  --> <VirtualHost *:<port_number>> (Check virtual hosts if applicable)

sudo systemctl restart apache2   # Debian/Ubuntu
sudo systemctl restart httpd     # RHEL-based
ss -tulpn | grep apache
___________________________________________________________________________________________________________________
# NGINX 
/etc/nginx/nginx.conf
/etc/nginx/sites-enabled/default
(usual locations)

server {                server {
    listen 80;  -->       listen <port_number>
}                       }

sudo nginx -t        #test first
sudo systemctl restart nginx
ss -tulpn | grep nginx
__________________________________________________________________________________________________________________
# Lighttpd
/etc/lighttpd/lighttpd.conf

server.port = 80 --> server.port = <port_number>

sudo systemctl restart lighttpd
__________________________________________________________________________________________________________________
# Caddy
/etc/caddy/Caddyfile

:80 {                            :<port_number> {
    root * /var/www/html  -->        root * /var/www/html
}                                }

sudo systemctl restart caddy
__________________________________________________________________________________________________________________
# Apache Tomcat
/conf/server.xml

<Connector port="80" protocol="HTTP/1.1"/> --> <Connector port="<port_number>" protocol="HTTP/1.1"/>

sudo systemctl restart tomcat
__________________________________________________________________________________________________________________

Feel free to add any more, obviously windows will be different so we will have to figure that out as well **-Niklas**
