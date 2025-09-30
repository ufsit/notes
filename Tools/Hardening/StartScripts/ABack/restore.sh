#!/bin/bash

#USE: Backup to backup server

rsync -avz -e ssh "$1:/.backup/$2/etc" /
if [ -d "$1:/.backup/$2/var/www" ]; then
  rsync -avz -e ssh "$1:/.backup/$2/var/www" /var 
fi
if [ -d "$1:/.backup/$2/var/www-html" ]; then
  rsync -avz -e ssh "$1:/.backup/$2/var/www-html" /var
fi
