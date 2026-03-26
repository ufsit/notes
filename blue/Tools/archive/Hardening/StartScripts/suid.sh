#!/bin/bash

# print suid binaries

SAFE_SUID_BINARIES=(
    "/usr/lib/polkit-1/polkit-agent-helper-1"
    "/usr/lib/dbus-1.0/dbus-daemon-launch-helper"
    "/usr/lib/openssh/ssh-keysign"
    "/usr/libexec/cockpit-session"
	"/usr/bin/mount"
	"/usr/bin/umount"
	"/usr/bin/chage"
	"/usr/bin/gpasswd"
	"/usr/bin/newgrp"
	"/usr/bin/su"
	"/usr/bin/pkexec"
	"/usr/bin/sudo"
	"/usr/bin/passwd"
	"/usr/bin/crontab"
    "/usr/bin/at"
	"/usr/sbin/grub2-set-bootflag"
	"/usr/sbin/pam_timestamp_check"
	"/usr/sbin/unix_chkpwd"
	"/usr/libexec/openssh/ssh-keysign"
	"/usr/bin/chsh"
	"/usr/bin/chfn"
	"/usr/bin/chage"
	"/usr/sbin/mount.nfs"
    "/usr/sbin/mount.cifs"

)

# Find all SUID binaries on the system
SUID_BINARIES=$(find / -perm -u=s -type f 2>/dev/null)

# Iterate over each SUID binary
while IFS= read -r binary; do
    # Check if the binary is in the list of known safe SUID binaries
    if [[ " ${SAFE_SUID_BINARIES[@]} " =~ " ${binary} " ]]; then
        echo "Safe SUID binary: $binary"
    else
        echo "Suspicious SUID binary: $binary"
    fi
done <<< "$SUID_BINARIES"

# print suspicious binaries (how do we do this?)
