#!/bin/sh
# chipmunk payload: create a backup archive on the target.
mkdir -p ~/baks
ts=$(date +%Y%m%d-%H%M%S)
out=~/baks/backup_$ts.tar.gz
tar czf "$out" /etc/passwd /etc/group /etc/hosts /etc/os-release /etc/ssh/sshd_config 2>/dev/null
echo "created $out"
ls -t ~/baks/*.tar.gz 2>/dev/null | head -1
