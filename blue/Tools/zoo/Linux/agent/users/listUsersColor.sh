#!/bin/sh
if id | grep -q "uid=0"; then
  :
else
  echo "You must run this script as root!"
  exit
fi
user_check() {
  if grep -q "^$1" admUsers.txt; then
    out="\033[36m"
  elif grep -q "^$1" regUsers.txt; then
    out="\033[32m"
  elif grep -q "^$1" essentialUsers.txt; then
    out="\033[37m"
  elif grep -q "^$1" serviceUsers.txt; then
    out="\033[33m"
  else
    out="\033[31m"
  fi

  out="$out$1\033[00m"
  for i in $(seq ${#1} 29); do
    out="$out "
  done
  out="$out\033[41m"
  if [ "$2" = "0" ]; then
    out="$out X"
  else
    out="$out  "
  fi
  if grep 'sudo\|wheel\|adm\|docker\|dial' /etc/group | grep -q "$1"; then
    out="$out X"
  else
    out="$out  "
  fi
  if [ -f "/etc/sudoers" ] &&  grep -v "#" /etc/sudoers | grep -q "$1"; then
    out="$out X"
  else
    out="$out  "
  fi

  out="$out\033[43m"
  if echo "$3" | grep -v "/bin/false" | grep -q -v "/usr/sbin/nologin"; then
    out="$out X"
  else
    out="$out  "
  fi
  if [ "$4" = "xx" ] || [ "$4" = "*x" ]; then
    out="$out  "
  else
    out="$out X"
  fi
  if w | awk '{print $1}' | grep -q "$1"; then
    out="$out X"
  else
    out="$out  "
  fi

  out="$out\033[42m"
  if [ -d "/home/$1" ]; then
    out="$out X"
  else
    out="$out  "
  fi
  if [ -f "/home/$1/.ssh/authorized_keys" ]; then
    out="$out X"
  else
    out="$out  "
  fi
  out="$out\033[00m"
  printf "$out\n"
}

printf "\nThis tool lists common misconfigurations for users, if you see a \033[41;1mX\033[0m that means the configuration exists for that user and should be remediated.\n\n"
printf "\033[1m   ,------------, \n>--  User types  --<\n   '------------'\033[0m\n - \033[36;1madmin user\033[0m: An allowed user with sudo privileges, as specified in \033[1madmUsers.txt\033[0m\n - \033[32;1mregular user\033[0m: An allowed user, as specified in \033[1mregUsers.txt\033[0m\n - \033[1mnecessarry service\033[0m: Do NOT mess with these users or the machine will break, as specified in \033[1messentialUsers.txt\033[0m\n - \033[33;1moptional service\033[0m: Users for a specific service. If you are not using that service, you should remove that user, as specified in \033[1mserviceUsers.txt\033[0m\n - \033[31;1munkown user\033[0m: This user has not been seen before and can safely be removed.\n\n"
printf "\033[1m   ,-------------, \n>-- Config checks --<\n   '-------------'\033[0m\n\033[31;1mRoot\033[0m\n - \033[41;1mR\033[0m: UID = 0\n - \033[41;1mG\033[0m: In sudo/wheel/adm/docker/dialout group\n - \033[41;1mS\033[0m: In sudoers file\n\033[33;1mSessions\033[0m\n - \033[43;1mL\033[0m: Can login\n - \033[43;1mN\033[0m: No passwd in /etc/passwd\n - \033[43;1mC\033[0m: Active connection\n\033[32;1mHome\033[0m\n - \033[42;1mH\033[0m: Has a home directory\n - \033[42;1mK\033[0m: Has SSH .authorized_keys\n\n"



printf "\033[01mUsername -------------------- \033[41m R G S\033[43m L N C\033[42m H K\033[00m\n"
grep -v "#" /etc/passwd | awk -F: '{print $1" "$2"x "$3" "$7"/"}' | (while read -r N X U L ; do
  user_check "$N" "$U" "$L" "$X"
done)
