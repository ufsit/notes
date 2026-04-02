#!/bin/sh
if id | grep -q "uid=0"; then
  :
else
  echo "You must run this script as root!"
  exit
fi
gen() {
  echo "$(shuf -n 5 plus/WORDLIST.TXT | paste -sd '0' -)"
}
out=""
users=$(grep -v '/sbin/nologin\|/bin/false\|sync\|blackteam' /etc/passwd | awk -F: '{print $1}')
for user in $users
do pass=$(gen)
  if openssl passwd --help 2>&1 | grep -q '\6'; then
    hashPass=$(openssl passwd -6 "$pass")
    sed -i "s|^$user:[^:]*:|$user:$hashPass:|" /etc/shadow
  else
    (echo $pass; echo $pass) | passwd $user
  fi
  out="$out\n$user: $pass"
done
printf "$out\n"
