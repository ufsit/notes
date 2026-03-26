#!/bin/bash

#Securing user ssh
for user in $(ls /home); do
  if [ -f /home/$user/.ssh/known_hosts ]; then
    rm /home/$user/.ssh/known_hosts
  fi
  if [ -f /home/$user/.ssh/authorized_keys ]; then
    echo "Authorized keys for $user:"
    cat /home/$user/.ssh/authorized_keys
    rename 's/authorized_keys/unauthorized_keys/' /home/$user/.ssh/authorized_keys
  fi
done
