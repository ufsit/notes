# Abstract

CCDC usually asks us to look for and report PII. This guide documents how to use hawk-eye to look for PII.  

hawk-eye works for Linux and Windows. We wrote scripts to automate the process for Linux but not for Windows yet.

# Getting the tools

Consider putting the blue repo someplace where hawk-eye won't see during a filesystem scan. `cd` to it then  

1. `git clone https://github.com/ufsit/blue.git`
2. `cd injects`

Note where you put the blue repo, since you'll need to edit the path in `hawk-eye.sh`.

# Getting connection info

We'll need to configure hawk-eye, but we need to go get the info to do so.

## Filesystem

### Linux
1. Run `directory-search.sh`: `sudo ./directory-search.sh`
2. This should create a file called `data_directories.txt`. Read it with your favorite text editor.
3. Copy the list.
4. Edit `hawk-eye/connection.yml`.
    - Under `filesystem` paste the directories and cut the ones you don't want to search on.

## MySQL
1. Login to MySQL server.
2. Take an inventory of databases: `SHOW DATABASES;`
3. Create a new user: `CREATE USER 'catcher'@'%' IDENTIFIED WITH mysql_native_password BY 'password';`
    - Maybe edit catcher host for more security
4. Grant read privileges to user: `GRANT SELECT ON *.* TO 'catcher'@'%';`
5. Flush privileges just in case: `FLUSH PRIVILEGES;`
6. Exit MySQL: `QUIT`
7. Edit `blue/injects/hawk-eye/connecion.yml`:
- Uncomment the `mysql` section. Only `host`, `port`, `user`, `password`, and `database` are required, so you may leave the rest commented. 
- Input values for `user`, `password` and `database` in the `mysql` according to the user you created. Note that each subsection only checks one database.

# Editing configs

# Execution
Run the hawk-eye script: `sudo ./hawk-eye.sh`