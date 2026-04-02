# Overview
* Uncomplicated Firewall, `ufw`, is a wrapper on top of `iptables`/`nftables` 
  * iptables is deprecated
  * nftables is iptables successor

# Basic UFW Rules
* Make sure you put these in order from TOP to BOTTOM as the order does matter. Doing otherwise could allow some connections to make it past our system
* If anything ever happens where you want to reset all the rules (and disable the firewall), use the command `sudo ufw reset`, just remember the firewall will be OFF after doing so.
* If there are services that you don't need (DNS is not required on many devices), just completely skip the code block for the service.<br><br>
* The firewall will process rules top-to-bottom, if there is conflict, the topmost rule will take precedence
* rule numbering will update after a single delete; if you need to delete multiple rules, take into account the renumbering after every delete 
  * TIP: delete rules starting at the bottom first, so you don't have to think about the renumbering in future deletes

<br>

ufw status with numbered rules
```
sudo ufw status numbered
```

Show apps recognized by UFW, the listed apps can be referenced in rules instead of ports 
```
sudo ufw app list
```

Allowing an app, from the above output
```
sudo ufw allow <app>
```

Block/Allow an IP or a range of IP addresses
```
sudo ufw allow from [IP_ADDRESS]    # can take a network/cidr or a host
sudo ufw deny from [IP_ADDRESS]     # can take a network/cidr or a host
```

Allow a port through
```
sudo ufw allow from <IP SOURCE FOR PROTO> to any port <port#> proto <tcp|udp>
sudo ufw allow out to <IP DEST FOR PROTO> port <port#>/<tcp|udp>
```

Safety defaults to minimize unnecessary outgoing/incoming traffic. (at the end)
```
sudo ufw default deny incoming
sudo ufw default deny outgoing
```

These can help us find if there are errors in how the firewall is setup or if connections are being interfered.
```
sudo ufw logging on
sudo ufw logging medium
```

Once you do all of the above (Don't forget SSH rules!) then enable.
```
sudo ufw enable
```

If you made changes to the rules while the firewall is active, run the following to reload the rules
```
sudo ufw reload
```

Insert/Delete rules at position `#` from the output of `status numbered`
```
sudo ufw insert [#] [RULE]
sudo ufw delete [#]
```


### Allowing Services - Examples
Allows SSH
```
sudo ufw allow from <IP WHERE WE SSH FROM> to any port 22 proto tcp
sudo ufw allow out to <IP WHERE WE SSH FROM> port 22/tcp
```

Allows HTTP requests
```
sudo ufw allow from <WEB IP> to any port 80 proto tcp
sudo ufw allow out to <WEB IP> port 80/tcp
```

Allows DNS requests
```
sudo ufw allow from <DNS IP> to any port 53 proto udp
sudo ufw allow out to <DNS IP> port 53/udp
```

Allows FTP to take place 
```
sudo ufw allow 20:21/tcp
```

### Nuclear Option: reset the firewall
* `sudo ufw reset`
* ufw will store a backup in `/etc/ufw`

# Additional Rule files
* There are more ufw rules files in `/etc/ufw`
  * `before.rules` and `after.rules`
  * these rules apply `before` and `after` the user-defined rules, respectively

### rule types in the before.rules file

* Input rules: Notice that some of the rules in this before-file file are `ufw-before-input` rules
    - These are rules that apply to traffic targeted to our machine

* Other rules are `ufw-before-forward` rules
    - These are rules that apply to traffic that our machinei s forwarding to other machines (i.e. the traffic is not intended for us, but has to go through a machine, like in the case of our CentOS router machine)