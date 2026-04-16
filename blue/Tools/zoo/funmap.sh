#!/bin/sh
ESC="\033["
HEADER="${ESC}1;4m"
CLEAR="${ESC}0m"

./install.sh
 
if [ -f pass.txt ]; then
  rm pass.txt
fi
 
if [ -f users.txt ]; then
  rm users.txt
fi
 
if [ -f ips.txt ]; then
  rm ips.txt
fi
 
if [ -f cracked.txt ]; then
  rm cracked.txt
fi
 
if [ -d fun ]; then
  rm -rf fun
fi
mkdir fun

roll="false"
fix="false"
path="$(pwd)"
 
while [ $# -gt 0 ]; do
  case $1 in
    -r | --roll) roll="true";;
    -f | --fix) fix="true";;
    -u | --users) echo "$2" | sed 's/,/\n/g' > users.txt
        shift;;
    -p | --passwords | --passwds) echo "$2" | sed 's/,/\n/g' > pass.txt
        shift;;
    -i | --ips) echo "$2" | sed 's/,/\n/g' > ips.txt
        shift;;
  esac
  shift
done

findFamily() {
  case "$1" in
    Debian) echo "Linux";;
    Ubuntu) echo "Linux";;
    Kali) echo "Linux";;
    RHEL) echo "Linux";;
    CentOS) echo "Linux";;
    Fedora) echo "Linux";;
    Rocky) echo "Linux";;
    Alma) echo "Linux";;
    Arch) echo "Linux";;
    Manjaro) echo "Linux";;
    Endeavour) echo "Linux";;
    Alpine) echo "Linux";;
    NixOS) echo "Linux";;
    FreeBSD) echo "BSD";;
    OpenBSD) echo "BSD";;
    NetBSD) echo "BSD";;
    DragonFly) echo "BSD";;
    *) echo "Windows";;
  esac
}

crack() {
  ip="$1"
  echo "Cracking $1"
  put="$(sshpass -p pass ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no user@$1 'hostname; uname -a' 2>&1 | grep 'Connection')"
  if [ -n "$put" ]; then
    return
  fi
  while read -r user; do
    while read -r pass; do
      output="$(sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$1 'hostname; uname -a' 2>&1 | grep -v 'denied\|closed\|reset' | sed ':a;N;$!ba;s/\n/|/g' | grep -v hostname)"
      if [ -n "$output" ]; then
        name="$(echo $output | awk -F'|' '{print $1}')"
        uname="$(echo $output | awk -F'|' '{print $2}')"
        if echo "$uname" | grep -qi debian; then
          distro="Debian"
        elif echo "$uname" | grep -qi ubuntu; then
          distro="Ubuntu"
        elif echo "$uname" | grep -qi kali; then
          distro="Kali"
        elif echo "$uname" | grep -qi rhel; then
          distro="RHEL"
        elif echo "$uname" | grep -qi centos; then
          distro="CentOS"
        elif echo "$uname" | grep -qi fedora; then
          distro="Fedora"
        elif echo "$uname" | grep -qi rocky; then
          distro="Rocky"
        elif echo "$uname" | grep -qi alma; then
          distro="Alma"
        elif echo "$uname" | grep -qi arch; then
          distro="Arch"
        elif echo "$uname" | grep -qi manjaro; then
          distro="Manjaro"
        elif echo "$uname" | grep -qi endeavour; then
          distro="Endeavour"
        elif echo "$uname" | grep -qi alpine; then
          distro="Alpine"
        elif echo "$uname" | grep -qi nixos; then
          distro="NixOS"
        elif echo "$uname" | grep -qi freebsd; then
          distro="FreeBSD"
        elif echo "$uname" | grep -qi openbsd; then
          distro="OpenBSD"
        elif echo "$uname" | grep -qi netbsd; then
          distro="NetBSD"
        elif echo "$uname" | grep -qi dragonfly; then
          distro="DragonFly"
        elif echo "$uname" | grep -qi linux; then
          distro="CentOS"
        else
          distro="Unknown"
        fi
	echo "$ip:$user:$pass" >> cracked.txt
        printf "Name: $name\nDistro: $distro\n" >> "fun/$ip/info.txt"
        return
      fi
    done < "pass.txt"
  done < "users.txt"
  if [ -f "fun/$ip/info.txt" ]; then
    :
  else
    printf "Name: N/A\nDistro: Unknown\n" >> "fun/$ip/info.txt"
  fi
}

makeJSON() {
  ip=$1
  crack="$(grep "$ip:" cracked.txt)"
  username="$(echo $crack | awk -F: '{print $2}')"
  passwd="$(echo $crack | awk -F: '{print $3}')"
  hostname="$(grep Name fun/$ip/info.txt | awk '{print $2}')"
  distro="$(grep Distro fun/$ip/info.txt | awk '{print $2}')"
  printf "{\n  \"properties\": {\n    \"ip\": \"$ip\",\n    \"hostname\": \"$hostname\",\n    \"distro\": \"$distro\"\n  },\n  \"services\": [\n"
  grep open "fun/$ip/nmap.txt" | awk '{print "    {\n      \"name\": \""$3"\",\n      \"port\": \""$1"\",\n      \"version\": \""$4"\"\n    },"}' | sed '$ s/.$//'
  printf "  ],\n  \"defaultCreds\": {\n"
  if echo "$crack" | grep -q -E "^$ip"; then
    printf "    \"user\": \"$username\",\n    \"passwd\": \"$passwd\"\n"
  else
    printf "    \"user\": \"N/A\",\n    \"passwd\": \"N/A\"\n"
  fi
  printf "  }\n}"
}

rollPasswd() {
  echo "Begin rolling passwords on $1"
  if grep -q "$1:" cracked.txt; then
    user="$(grep "$1:" cracked.txt | awk -F: '{print $2}')"
    pass="$(grep "$1:" cracked.txt | awk -F: '{print $3}')"
    if [ "$user" = "root" ]; then
      remotePath="/root"
    else
      remotePath="/home/$user"
    fi
    sshpass -p $pass scp -r "$path/plus" $user@$1:
    sshpass -p $pass scp -r "$path/$2/agent" $user@$1:
    sshpass -p $pass ssh -tt $user@$1 "$remotePath/agent/exec.sh $pass rollPasswd.sh" > "fun/$ip/pass.txt"
  fi
  echo "Finished rolling passwords on $1"
}

if [ -f users.txt ]; then
  :
else
  printf "${HEADER}USERS${CLEAR}\n"
  read -p "Enter default user: " user
  while true; do
    if [ "$user" = "done" ]; then
      break
    else
      echo "$user" >> "$path/users.txt"
    fi
    read -p "Enter default user. [Type done to stop]: " user
  done
fi  

if [ -f pass.txt ]; then
  :
else
  printf "${HEADER}PASSWDS${CLEAR}\n"
  read -p "Enter default password: " pass
  while true; do
    if [ "$pass" = "done" ]; then
      break
    else
      echo "$pass" >> "$path/pass.txt"
    fi
    read -p "Enter default password. [Type done to stop]: " pass
  done
fi

ipRegex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
subRegex='^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$'
if [ -f ips.txt ]; then
  :
else
  printf "${HEADER}IPS${CLEAR}\n"
  read -p "Enter a IP or subnet to scan: " sub
  while echo "$sub" | grep -q -E "$ipRegex|$subRegex"; do
    echo "$sub" >> ips.txt
    read -p "Enter a IP or subnet to scan. [Type done to stop]: " sub
  done
fi

while read -r ip; do
  if echo $ip | grep -q -E "$subRegex"; then
    nmap -PR -PE -PP -PM -PO2 -PS21,22,23,25,80,110,113,135,137,143,443,445,691,993,995,1433,1521,2483,2484,3306,8008,8080,8443,7680,31339 -PA80,113,443,10042 -sn "$sub" | grep report | awk '{print $5}' >> Rips.txt
  else
    echo $ip >> Rips.txt
  fi
done < ips.txt

sort -u Rips.txt > ips.txt
sed -i -E 's/^(\S+)\s+.(.*).$/\2 /' ips.txt

echo "Start scanning!"
while read -r ip; do
    mkdir "fun/$ip"
    nmap -sS -sV "$ip" > "fun/$ip/nmap.txt" 2>/dev/null &
done < ips.txt



cat index.template.html > index.html
ybase=25
xbase=0
lines=$(wc -l < ips.txt)
while read -r ip; do
  crack "$ip"
  hostname="$(grep Name fun/$ip/info.txt | awk '{print $2}')"
  distro="$(grep Distro fun/$ip/info.txt | awk '{print $2}')"
  fam="$(findFamily $distro)"

  if [ "$roll" = "true" ]; then
    rollPasswd "$ip" "$fam" &
  fi

  makeJSON $ip > "fun/$ip/data.json"
  
  printf "                { data: { id: \"$ip\", sub: \"0.0.0.0\", label: \"$ip\\\\n$hostname\", hostname: \"$hostname\", distro: \"$distro\", image: \"assets/$distro.png\" }, position: { x: $xbase, y: $ybase } }," >> index.html
  count=$((count + 1))
  if [ "$count" -eq 8 ]; then
    count=0
    lines=$((lines - 8))
    if [ "$lines" -lt "8" ]; then
      xbase=$((8*(7-lines)))
    else
      xbase=0
    fi
    ybase=$((ybase+25))
  else
    xbase=$((xbase+16))
  fi
done < ips.txt

cat index.end.html >> index.html

cp watcher ~/Downloads
cd ~/Downloads
./watcher
