dnf install samba -y
adduser backupuser
mkdir /home/backupuser/shared
chown backupuser /home/backupuser/shared
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
systemctl enable smb --now
systemctl restart smb

semanage fcontext --add --type "samba_share_t" "/home/backupuser/shared(/.*)?"
restorecon -R /home/backupuser/shared
