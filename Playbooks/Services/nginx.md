* `/etc/nginx/nginx.conf`
* minimize information disclosure
  * `server_tokens off`
* Implement HTTPS
```
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
```
* Disable unused HTTP methods
```
if ($request_method !~ ^(GET|HEAD|POST)$) {
  return 405;
}
```
* limit rate of requests
  * `limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;`
* secure connection headers
```
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
add_header X-XSS-Protection "1; mode=block";
```
* backup configurations
  * `rsync -av -e ssh <source_files>  <remote_user>@<remote_ip>:<remote_path>`
* Disable server-side code execution on upload directories
```
location /path/to/upload/directory {
  location ~ \.php$ { return 403; }
}
```
* Content Security Policy (CSP) Implementation
  * `add_header Content-Security-Policy "default-src 'self'; script-src 'self'";`

<br>

* Configure connections to DB over SSL


#### Sources
* [hackviser](https://hackviser.com/tactics/hardening/nginx)