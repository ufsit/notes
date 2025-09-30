# Using rkhunter
At some point during the start you should run rkhunter to check if there are any rootkits. Getting started is very simple:
- `sudo apt install rkhunter`
- You can use `rkhunter --propupd` to update to latest version (probably unnecessarry)
- Do the thing: `rkhunter --check`
  - You can check output later in `var/log/rkhunter.log`
  - **RED BAD**, go fix it if you get any warnings
