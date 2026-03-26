# cron
* `systemctl start|stop|restart cron`
* Cron is the scheduled tasks service. As part of the cron program, you get what are called "cron tabs"
    - These are files that include automatic commands

* The question, now, is: How many of these crontabs are there and where are they on our system?
    - `crontab -e` to edit the current user's crontab
    - Take a look at the explanation given in the default crontab file, the comments indicate the syntax and some examples of how to write a cronjob that executes periodically.

**Example**
```
0 0 * * 0 /home/br/.local/bin/paccache-clear
```
  - "Execute the program `/home/br/.local/bin/paccache-clear` on the 0th minute, on the 0th hour, on every day of the month, on every month of the year, on the 0th day of the week"
  - In other words, it runs at 0:00 on every Sunday.

<br>

__Easy crontab parser/explainer__: [https://crontab.guru](https://crontab.guru)


## Config locations
* Location of all user crontabs; they will be named based on the user
  * `/var/spool/cron/crontabs/*`
  * `/var/spool/cron/*`
* Location of system-wide crontabs
  * `/etc/cron*`
  * `/etc/cron.d/*` - cronjobs for services
  * `/etc/cron.daily/*` - directory for system-wide programs that run daily
  * `/etc/cron.hourly/*` - hourly
  * `/etc/cron.weekly/*` - weekly
  * `/etc/cron.monthly/*` - monthly
  * `/etc/crontab`
    * it can specify what user can run a cronjob
* `/var/spool/anacron/*`
