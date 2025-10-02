# auditd
Auditd, paired with the right config, can make Linux command-line monitoring/logging __very__ powerful.

You can even pair it with a SIEM (Security Information and Event Management) program such as Splunk to hook up multiple machines to a centralized logging server (not covered here for now).

1. Install with your package manager (e.g. `sudo apt get auditd`)
2. `sudo systemctl enable --now auditd`
3. `sudo systemctl status auditd`
4. (Most important step): Download a good, security-focused config: https://github.com/Neo23x0/auditd
5. Copy that config over to /etc/audit/auditd.conf
6. Restart service
7. Search through auditd logs with `ausearch -k <key>` where 'key' is the label for each type of security event (check the config file -- it explains further in its comments)