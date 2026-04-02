apt-get update
apt-get install samba cifs-utils smbclient -y
adduser backupuser
mkdir /home/backupuser/shared
chown /home/backupuser/shared backupuser
cat <<EOF >> /etc/samba/smb.conf
[backup]
  comment = Backup folder
  path = /home/backupuser/shared
  writable = yes
  guest ok = no
  valid users = backupuser
  force create mode = 770
  force directory mode = 770
  inherit permission = yes
EOF
smbpasswd -a backupuser
smbpasswd -e backupuser
systemctl restart nmbd
systemctl enable nmbd
