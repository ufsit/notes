# Basic UFW Rules
* Make sure you put these in order from TOP to BOTTOM as the order does matter. Doing otherwise could allow some connections to make it past our system, and if you want to check the order of rules, you can do `sudo ufw status numbered`.
* If anything ever happens where you want to reset all the rules (and disable the firewall), use the command `sudo ufw reset`, just remember the firewall will be OFF after doing so.
* If there are services that you don't need (DNS is not required on many devices), just completely skip the code block for the service.

<br>

* The firewall will process rules top-to-bottom, if there is conflict, the topmost rule will take precedence
* numbering will update after a single delete; if you need to delete multiple rules, take into account the renumbering after every delete 
  * TIP: delete rules starting at the bottom first, so you don't have to think about the renumbering in future deletes

<br>

* Show apps recognized by UFW, the listed apps can be referenced in rules instead of ports 
```
sudo ufw app list
```

* Block/Allow an IP or a range of IP addresses
```
sudo ufw allow from [IP_ADDRESS]    # can take a network/cidr
sudo ufw deny from [IP_ADDRESS]     # can take a network/cidr
```

* Allows SSH
```
sudo ufw allow from <IP WHERE WE SSH FROM> to any port 22 proto tcp
sudo ufw allow out to <IP WHERE WE SSH FROM> port 22/tcp
```

* Allows HTTP requests
```
sudo ufw allow from <WEB IP> to any port 80 proto tcp
sudo ufw allow out to <WEB IP> port 80/tcp
```

* Allows DNS requests
```
sudo ufw allow from <DNS IP> to any port 53 proto udp
sudo ufw allow out to <DNS IP> port 53/udp
```

* Allows FTP to take place 
```
sudo ufw allow 20:21/tcp
```

* Safety defaults to minimize unnecessary outgoing/incoming traffic.
```
sudo ufw default deny incoming
sudo ufw default deny outgoing
```

* These can help us find if there are errors in how the firewall is setup or if connections are being interfered.
```
sudo ufw logging on
sudo ufw logging medium
```

* Insert/Delete rules at position `#` from the output of `status numbered`
```
sudo ufw insert [#] [RULE]
sudo ufw delete [#]
```

* Once you do all of the above (Don't forget SSH rules!) then enable.
```
sudo ufw enable
```

* If you made changes to the rules while the firewall is active, run the following to reload the rules
```
sudo ufw reload
```
  

