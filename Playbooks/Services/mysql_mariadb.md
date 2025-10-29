* `/etc/my.cnf` (RHEL); `/etc/mysql/my.conf` OR `/etc/mysql/mysql.conf.d/mystd.cnf` (Ubuntu)
* secure installation (set root's passwd, disable root remote login, remove anon users and test db)
  * `mysql_secure_installation` OR `mariadb_secure_installation`
* bind database server to only the website's IP address: only allow remote connections from it
  * `bind-address = 127.0.0.1, <web_server_ip>`
* disable access to the local filesystem (`LOAD DATA` clauses)
  * `local-infile=0`
* enable logging
  * mysql
    * `log=/var/log/mysql.log`
  * mariadb
    * `log_error = /avr/log/mysql/error.log`
    * `general_log=1`
    * `general_log_file = /var/log/mysql/mysql.log`
* verify logs are not world readable
  * `ls -l /var/log/mysql*`
* verify conf file has appropriate permissions:
  * `chmod 644 /etc/my.cnf`
* delete mysql shell history
  * `cat /dev/null > ~/.mysql_history`
  * `ln -sf /dev/null ~/.mysql_history`
* verify databases are managed by a dedicated users (when applicable)
  * users required by the db, host should contain the webapp's IP address
```sql
CREATE USER 'test_db_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT SELECT,UPDATE,DELETE ON test_db.* TO 'test_db_user'@'localhost';
FLUSH PRIVILEGES;
```
* verify no users are configured without a password or an associated host (`%` are empty passwd)
  * `SELECT User,Host,Password FROM mysql.user;`
* Update a user with a password if necessary
  * `UPDATE mysql.user SET Password=PASSWORD('secure_passwd') WHERE User='target_user';`
* Update a user's host field to contain benign addresses (except for the db's user, write localhost)
  * `UPDATE mysql.user SET Host='localhost' WHERE User="demo-user";`
* Delete empty/malicious/unnecessary users
```sql
DELETE FROM mysql.user WHERE User="";
FLUSH PRIVILEGES;
```
* show privileges for users
  * `SHOW GRANTS for 'user'@'host';`
* remove privileges 
  * `REVOKE <priv> ON test_db.* FROM 'user'@;host';`
* change the root user's login name
```sql
RENAME USER 'root'@'localhost' to 'newAdminUser'@'localhost';
FLUSH PRIVILEGES;
```

* Enable connections over SSL

#### Sources
1. [teaming](https://www.tecmint.com/mysql-mariadb-security-best-practices-for-linux/)
2. [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
3. [Snap Shooter](https://snapshooter.com/learn/mysql/top-tips-secure-mysql#5-secure-mysqlmariadb-connection-with-ssltls)