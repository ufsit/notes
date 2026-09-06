# Elephant
> Elephants have an incredibly good memory, and their job in this zoo is to remember and manage our passwords.

* Manages user passwords across every host, linux and windows.
* Flow: `initAdmin` collects admin creds + IPs, then **fingerprints each host's OS
  via hawk's nmap** and writes `USER IP PASSWORD OS DOMAIN`.
* **Linux roll:** parse `/etc/passwd`, hash new passphrases, roll admin then
  non-admin users over ssh. Source of truth: `passwd_roll_log/clear.txt`.
* **Windows roll:** push `roll_passwords.ps1` (+ `no_change.txt`, `words.txt`) via
  nxc and runs it (`-L` local / `-D` domain). The rolled creds come back over the
  command's **stdout** (marked `ZOOCRED:`) — never written to the target's disk —
  and are saved to `passwd_roll_log/clear_win.txt` (chmod 600). `Administrator` is
  excluded so you keep access. Domain vs local is taken from the host's DOMAIN column.
