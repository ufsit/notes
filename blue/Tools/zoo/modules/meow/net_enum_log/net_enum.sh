#!/bin/sh
printf "===== HOSTNAME =====\n"
hostname 
hostname -f 2>/dev/null

printf "\n===== IP ADDRESSES =====\n"
ip -brief addr 2>/dev/null || ifconfig -a

printf "\n===== ROUTING TABLE =====\n"
ip route 2>/dev/null || route -n

printf "\n===== DNS CONFIGURATION =====\n"
cat /etc/resolv.conf

printf "\n===== /etc/hosts =====\n"
cat /etc/hosts

printf "\n===== SYSTEMD RESOLVED (if present) =====\n"
resolvectl status 2>/dev/null || systemd-resolve --status 2>/dev/null

printf "\n===== NETWORK INTERFACES =====\n"
ip link show 2>/dev/null || ifconfig -a

printf "\n===== ARP TABLE =====\n"
ip neigh 2>/dev/null || arp -a

printf "\n===== DEFAULT GATEWAY =====\n"
ip route | grep default 2>/dev/null || route -n | grep '^0.0.0.0'

printf "\n===== NETWORK MANAGER STATUS (if present) =====\n"
nmcli device status 2>/dev/null

printf "\n===== OPEN PORTS =====\n"
netstat -lntu 2>/dev/null

