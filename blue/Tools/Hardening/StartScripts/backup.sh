#!/bin/bash

#USE: Backups up important files to local directory. If there are other files you would like to back up, you can manually do so by adding rsync commands

if [ ! -d "/.backup" ]; then
  mkdir /.backup
fi
rsync -av /etc "/.backup"
if [ -d "/var/www" ]; then
  rsync -av /var/www "/.backup"
fi
if [ -d "/var/www-html" ]; then
  rsync -av -e ssh /var/www-html "/.backup"
fi
rsync -av /home "/.backup"
