#!/bin/bash

#USE: Restores data using backup.

if [ ! -d "/.backup" ]; then
  echo -e "\e[31mWARNING: No backup exists!\e[0m"
else
  rsync -av /.backup/etc "/"
  if [ -d "/var/www" ]; then
    rsync -av /.backup/var/www "/var"
  fi
  if [ -d "/var/www-html" ]; then
    rsync -av -e ssh /.backup/var/www-html "/var"
  fi
  rsync -av /.backup/home "/"
fi
