#!/bin/bash

#USE: Backup to backup server

rsync -avz -e ssh /etc "$1:/.backup/$2"
if [ -d "/var/www" ]; then
  rsync -avz -e ssh /var/www "$1:/.backup/$2"
fi
if [ -d "/var/www-html" ]; then
  rsync -avz -e ssh /var/www-html "$1:/.backup/$2"
fi
