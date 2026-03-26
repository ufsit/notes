# Runbook

1. Find and fix [user misconfigurations](#root)
    <details>
        <summary>Click here to see the steps to setup <a href="https://github.com/pyukey/BlueDaBaDee/tree/main/Linux/usrs">the tool</a></summary>
        <ol>
        <li> <code>git clone https://github.com/pyukey/BlueDaBaDee.git</code></li>   
            If you do not have access to the internet nor git, there are some backup plans. You can either get the repo locally and <code>scp</code> it over. Or, host a web server locally via <code>python3 -m http.server</code> and then on the target machine curl the files you want. 
        <li> <code>cd BlueDaBaDee/Linux/usrs</code></li>
        <li> <code>chmod 764 *.sh</code></li>
        <li> <code>./listUsersColor.sh</code></li>   
        </ol>
    </details>
2. Find and fix [file permissions](#important-files)

The results should look like below. **X** indicates the configuration exists, read below to patch them.

![image](https://hackmd.io/_uploads/r1wcR9IGll.png)

## Root

### R: [UID = 0](/Systems/Linux/users.md#etcpasswd)

- `usermod -u <NEW-UID> <USER>` or
- Manually modify the 3rd field of `/etc/passwd`

### G: [sudoers group](/Systems/Linux/users.md#etcgroup)

- `usermod -G <NEW-LIST-OF-GROUPS> <USER>` or
-  Manuall modify `/etc/group`

### S: [sudoers file](/Systems/Linux/users.md#etcsudoers)

- Run this script, which removes *all* times that user shows up:
  ```
  for n in $(grep -n -v "#" /etc/sudoers | grep <USER> | awk '{print $1}'); do
    sed -i '$nd' /etc/sudoers
  done
  ```
- Manually go through `/etc/sudoers`, remove unneeded lines

## Sessions

### L: [Can login](/Systems/Linux/users.md#etcpasswd)

Only authorized users should be able to login, and *definitely* not system users.   
**Note:** `sync` should be able to login with `/bin/sync`

- `usermod -s "/bin/false" <USER>` or
- Manually modify the last field of `/etc/passwd` to `/usr/sbin/nologin` or `/bin/false` and
- Make sure neither of those binaries have been replaced with `bash` (e.g. check `sha256sum` or execute the binary yourself)

### N: No passwd in `/etc/passwd`

This has a few implications:

1. You can now login as that user with no passwd.   
   This is also true if the passwd field is blank in `/etc/shadow`
2. Now whenever the passwd is changed, the hash is readable in `/etc/passwd`

<span style="color:lightgreen">Remediation</span>
- Change the 2nd field in `/etc/passwd` to `x`
- Change the 2nd field in `/etc/shadow` to `*` or `!` if that user is not meant to have a passwd.

### C: Active connection

The user is currently logged in!  <span style="color:red">Need a good way of killing these connections</span>.

## Home

### H: Has a home directory

- Check each user's home for malicious executables
- Check each `/home/<USER>/.bashrc` and `.bash_profile` for anything sus
   - `grep alias .bashrc` &rarr; look for malicious aliases. Could also be in `.bash_aliases`
   - `tail .bashrc` &rarr; look for any malicious commands
- <span style="color:red">BE CAREFUL as this is not recoverable: </span>Simply **nuke** the directory w/ `rm -rf /home/<USER>`

### K: SSH authorized keys

- `mv /home/<USER>/.ssh/authorized_keys /home/<USER>/.ssh/author1zed_keys`   
   Since you renamed the file, it is no longer effective. By typo-squatting, the attacker is less likely to notice.


# Important files

- `chmod 644 /etc/passwd`&rarr; [learn more](/Systems/Linux/users.md#etcpasswd)
- `chmod 644 /etc/group`&rarr; [learn more](/Systems/Linux/users.md#etcgroup)
- `chmod 640 /etc/shadow`&rarr; [learn more](/Systems/Linux/users.md#etcshadow)
- `chmod 640 /etc/gshadow`&rarr; [learn more](/Systems/Linux/users.md#etcgshadow)
- `chmod 440 /etc/sudoers`&rarr; [learn more](/Systems/Linux/users.md#etcsudoers
)