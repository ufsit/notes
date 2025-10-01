# apt
* verify `/etc/apt/sources.list` contains valid entries
* verify `/etc/apt/preferences.d/*` files are benign
* `dpkg --verify` to verify integrity of all apt-installed packages
  * modified package output: `??5??????`; not all these are malicious
  * reinstall bad package: `sudo apt --reinstall [PACKAGE]`
* Custom installed packages
  * `sudo comm -13 <(cat /var/lib/dpkg/info/*.list | sort -u) <(find / | sort -u)`

# rpm
* `sudo rpm -Va --nomtime`
* any line with 5 (..5......) == bad package
* reinstall with: `sudo yum reinstall [PACKAGE]`
* Custom installed packages
  * `sudo comm -13 <(rpm -qla | sort -u) <(find / | sort -u)`