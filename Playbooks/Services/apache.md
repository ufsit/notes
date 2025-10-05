* `/etc/httpd/conf/httpd.conf` (RHEL) or `/etc/apache.apache2.conf` (Ubuntu)
* Hide Apache version and OS Identity
```
ServerTokens Prod
ServerSignatuer Off
```
* Disable directory listing, modify `.htaccess` <!-- TODO: verify -->
  * `Options -Indexes`
* Force HTTPS use, redirect HTTP traffic
  * `Redirect "/" "https://<site_domain>/"`
* Implement `ModSecurity` (a WAF) and `ModEvasive` (DoS prevention) <!-- TODO: provide steps, maybe somewhere else --> 
* Limit Request Size, prevent buffer overflow
  * `LimitRequestBody 102400`
* Use Strong SSL/TLS ciphers, on `ssl.conf`
```
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite HIGH:!aNULL:!MD5
```
* backup configurations
  * `rsync -av -e ssh <source_files>  <remote_user>@<remote_ip>:<remote_path>`
* Secure Apache Against XSS; use `mod_headers` to add CSP headers
  * `Header set Content-Security-Policy "default-src 'self'; script-src 'self'; object-src 'none'"`

<br>
<!-- TODO: connections over SSL to the DB: required or allowed?; see what needs to be done on db playbook -->

#### Sources
* [hackviser](https://hackviser.com/tactics/hardening/apache)
