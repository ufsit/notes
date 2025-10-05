* `/etc/postgresql/<version>/main/postgresql.conf`
* `/etc/postgresql/<version>/main/pg_hba.conf`
* `/etc/postgresql/<version>/main/ident_file`

<br>

* `postgresql.conf`
* restrict listen address to the db and other trusted IPs
  * `listen_address = 'localhost, <webapp_ip>'`
* revoke privileges on schema PUBLIC
```sql
REVOKE ALL ON DATABASE demo FROM public;
REVOKE ALL ON DATABASE public FROM public;
```
* roll passwords through `psql` as the root db user (no plaintext logs)
```
sudo -u postgres psql
\passord target_user
--> password prompt
\q
```
* enable SSL connections
   <!-- See source 2  -->
* verify applications are not running as the superuser

* `pg_hba.conf`
* specify users that are allowed to connect remotely, with an appropriate hash
```
host    my_db   my_user     <ip>/<cidr>     scram-sha-256       # remote connection
local   my_db   my_user                     scram-sha-256       # local connection
```

### Sources
1. [CyberTec](https://www.cybertec-postgresql.com/en/postgresql-security-things-to-avoid-in-real-life/)
2. [CyberTec - SSL](https://www.cybertec-postgresql.com/en/setting-up-ssl-authentication-for-postgresql/)
3. 