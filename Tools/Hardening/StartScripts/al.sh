#!/bin/bash

#USE: Checks for aliases. Will print any sus aliases.

#Function to check for mmalicious aliases in a file
check_aliases() {
  local file="$1"
  local malicious_aliases=0

  #Check if the file exists
  if [ -f "$file" ]; then
    echo "Checking $file for malicious aliases..."

    #Search for aliases defined in the file
    while IFS= read -r line; do
      #Check if the line starts with "alias" and contains mal
      if [[ "$line" == alias\ * && "$line" =~ (rm\ |mv\ |cp\ |wget\ |curl\ |nc\ |netcat\ |sh\'$) ]]; then
        echo -e "\e[31mPotential malicious alias found: $line\e[0m"
        malicious_aliases=$((malicious_aliases+1))
      fi
    done < "$file"

    if [ "$malicious_aliases" -eq 0 ]; then
      echo "No malicious aliases found in $file."
    fi
  else
    echo "File $file does not exist."
  fi
}

#Check root
echo -e "\e[32mChecking root:\e[0m"
  if [ -f /root/.bashrc ]; then
    check_aliases /root/.bashrc
  fi
  if [ -f /root/.bash_profile ]; then
    check_aliases /root/.bash_profile
  fi
  if [ -f /root/.bash_aliases ]; then
    check_aliases /root/.bash_aliases
  fi
  if [ -f /root/.zshrc ]; then
    check_aliases /root/.zshrc
  fi
  if [ -f /root/.profile ]; then
    check_aliases /root/.profile
  fi

# Check common user shell configuration files
for user in $(ls /home); do
  echo -e "\e[32mChecking $user:\e[0m"
  if [ -f /home/$user/.bashrc ]; then
    check_aliases /home/$user/.bashrc
  fi
  if [ -f /home/$user/.bash_profile ]; then
    check_aliases /home/$user/.bash_profile
  fi
  if [ -f /home/$user/.bash_aliases ]; then
    check_aliases /home/$user/.bash_aliases
  fi
  if [ -f /home/$user/.zshrc ]; then
    check_aliases /home/$user/.zshrc
  fi
  if [ -f /home/$user/.profile ]; then
    check_aliases /home/$user/.profile
  fi
done

# Check global shell configuration files
echo -e "\e[32mChecking global:\e[0m"
if [ -f /etc/zshrc ]; then
  check_aliases /etc/zshrc
fi
if [ -f /etc/profile ]; then
  check_aliases /etc/profile
fi
if [ -f /etc/bash.bashrc ]; then
  check_aliases /etc/bash.bashrc
fi

#Check default configs

if [ -f /etc/skel ]; then
  check_aliases /etc/skel
fi
