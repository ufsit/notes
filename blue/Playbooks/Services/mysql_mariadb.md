* Configuration Files
```
-- RHEL
/etc/my.cnf`

-- Ubuntu
/etc/mysql/my.conf                    # references the below files
/etc/mysql/mysql.conf.d/mysql.conf    # client config
/etc/mysql/mysql.conf.d/mysqld.conf   # server config
```
<br>

* secure installation (set root's passwd, disable root remote login, remove anon users and test db)
```
mysql_secure_installation
mariadb_secure_installation
```
<br>

* bind database server to only the website's IP address: only allow remote connections from it
```
bind-address = 127.0.0.1, <web_server_ip>
```
<br>

* disable access to the local filesystem (`LOAD DATA` clauses)
```
local-infile=0
```
<br>

* enable logging
```
-- mysql
--- /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
general_log = 1
general_log_file = /path/to/query_log.log

-- mariadb
log_error = /var/log/mysql/error.log
general_log=1
general_log_file = /var/log/mysql/mysql.log
```
<br>

* verify logs are not world readable
```
ls -l /var/log/mysql*
```
<br>

* verify conf file has appropriate permissions:
```
chmod 644 /etc/my.cnf
```
<br>

* delete mysql shell history
```
cat /dev/null > ~/.mysql_history
ln -sf /dev/null ~/.mysql_history
```
<br>

### User Management
* verify databases are managed by a dedicated users (when applicable)
  * users required by the db, host should contain the webapp's IP address
```sql
CREATE USER 'test_db_user'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'secure_password';
FLUSH PRIVILEGES;
```
<br>

* Delete bad users
```sql
DELETE FROM mysql.user WHERE User="bad-user";
FLUSH PRIVILEGES;
```
<br>

### Password Management
* null passwords? (`%` means empty passwd)
```sql
SELECT user, authentication_string, plugin FROM mysql.user;
```
<br>

* Update a password
```sql
ALTER USER 'username'@'host' IDENTIFIED BY 'new_password';
```
<br>

### Permissions

* list, remove, grant perms
```sql
-- listing
SELECT * FROM information_schema.user_privileges WHERE GRANTEE="'user'@'host'";
SHOW GRANTS FOR 'username'@'host';

-- removing
REVOKE ALL PRIVILEGES ON *.* FROM 'user'@'host';  --disable a user for all dbs and their tables

-- granting
GRANT <priv> ON target_db.* TO 'user'@'host';
FLUSH PRIVILEGES;
```
<br>


### Misc
* change the root user's login name
```sql
RENAME USER 'root'@'localhost' to 'newAdminUser'@'localhost';
FLUSH PRIVILEGES;
```
<br>

* malicious host field? (except for the db's user, write localhost)
```sql
UPDATE mysql.user SET Host='localhost' WHERE User="demo-user";
```
<br>

* list authentication plugin status
```sql
SELECT PLUGIN_NAME, PLUGIN_STATUS
FROM information_schema.plugins;
```

* Password policies on the `validate_password` plugin
```sql
SHOW VARIABLES LIKE 'validate_password%';
```
#### Sources
1. [tecmint](https://www.tecmint.com/mysql-mariadb-security-best-practices-for-linux/)
2. [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
3. [Snap Shooter](https://snapshooter.com/learn/mysql/top-tips-secure-mysql#5-secure-mysqlmariadb-connection-with-ssltls)
4. [devart](https://www.devart.com/dbforge/mysql/studio/mysql-grant-revoke-privileges.html)