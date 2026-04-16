#!/bin/sh
if id | grep -q "uid=0"; then
  :
else
  echo "You must run this script as root!"
  exit
fi

undo() {
  sleep $1
  num=$(iptables -L INPUT --line-numbers | tail -1 | awk '{print $1}')
  iptables -D INPUT $num
  num=$(iptables -L OUTPUT --line-numbers | tail -1 | awk '{print $1}')
  iptables -D OUTPUT $num
  printf "\n\033[01m\033[33mBlackout Over!\033[00m\n"
}
block(){
  iptables -A INPUT -j DROP
  iptables -A OUTPUT -j DROP
}

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ips=$(ss | grep ssh | awk '{print $6}' | awk -F: '{print $1}')
echo "SSH connections from: $ips"

for ip in $ips
do echo "Allow $ip? [y|n]"
read ans
case $ans in
  y) iptables -A INPUT -s "$ip" -p tcp --dport 22 -j ACCEPT; iptables -A OUTPUT -d "$ip" -p tcp --sport 22 -j ACCEPT;;
  n) :;;
esac
done

#DON'T TOUCH
undo 3 &
block

echo "Say something if you are still connected:"
read connected

sleep 3
undo 60 &
block

echo "You have 1 minute to harden your system!"
