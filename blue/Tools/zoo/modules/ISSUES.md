# Zoo module tracker — one issue per animal

All 15 modules were live-verified against a loopback SSH target. `meow.sh` is a
sourceable driver library (`meow_run` / `meow_deploy` / `meow_fetch` / `meow_push`
/ `genPasswd`); every module has a `<module>.sh` that calls into it.

**nmap retest:** the static nmap 7.95 (self-contained binary + refreshed `nmap-data`)
was re-tested end to end — hawk performed real `-sV` service detection and every
other module re-passed with it in place.

Legend: ✅ done · ⚠️ works but needs implementation work · 🔒 needs root/live infra to finish

---

## 1 · elephant — Password Roll ✅
**Status:** works. Refactored to source meow; pulls the user list and generates
`0`-separated passphrases via `genPasswd`, then rolls admin + non-admin passwords.
**Verified:** read path pulled 10 users and generated `clear.txt`/hashes on the live target (roll itself needs a sudo-capable target to confirm).
**Remaining:**
- [ ] Graceful handling when SSH auth fails (today it emits `column`/`grep: No such file` noise instead of a clear "login failed" message).

## 2 · nematode — Network Enum ✅
**Status:** works. `nematode.sh` pushes `net_enum.sh` to every host and logs per-host enumeration (the old bug — running it locally — is fixed).
**Verified:** per-host HOSTNAME/IP/routing/DNS/ports captured to `net_enum_log/`.
**Remaining:**
- [ ] Add the service-relationship mapping the README describes (map which host runs which service, e.g. web server → its DB on another host).

## 3 · elk — Deploy Elastic Agent ⚠️🔒
**Status:** works "on paper" — orchestrator + transport verified, all four assets present in `elk/` (`linux_agent.sh`, `archive_install.sh`, `alpine-beats.tar.gz`, `rules.conf`).
**Verified:** scp/ssh transport path; full install NOT run (85 MB beats + real Elastic).
**Remaining:**
- [ ] End-to-end test against a live Elastic/Kibana stack (feeds server IP, fingerprint, password via heredoc).
- [ ] Confirm agents enroll and ship logs.

## 4 · suricata — Deploy Suricata ⚠️🔒
**Status:** works as a readiness check only — reports whether suricata is installed/active.
**Verified:** reports "NOT installed" on the target.
**Remaining:**
- [ ] Implement the actual install + config deploy.
- [ ] Wire `eve.json` → ELK pipeline (per README).

## 5 · chipmunk — Get Backups ✅
**Status:** works. Creates a backup archive on each host, pulls the newest into `baks/<ip>/`.
**Verified:** valid `.tar.gz` created on target and pulled back.
**Remaining:**
- [ ] Restore-from-backup flow (README: create **and restore**).
- [ ] Retention/rotation + a "host backups" mode.

## 6 · hawk — Nmap Scan ✅
**Status:** works with the new self-contained static nmap 7.95 (binary + `nmap-data` bundled; no host deps).
**Verified:** real `-sV` detection of `OpenSSH` on the loopback target; finds open ports.
**Remaining:**
- [ ] (Optional) OS detection `-O`/`-sS` auto-enables when run as root — confirm on a root operator box.
- [ ] Feed results into the network diagram generator.

## 7 · meerkat — Service Health ✅
**Status:** works. Reports failed units, running services, listening sockets, uptime, disk.
**Verified:** health probe logged from the target.
**Remaining:**
- [ ] Define alert thresholds / a pass-fail summary rather than raw dump.

## 8 · lynx — PAM Audit ✅
**Status:** works. Audits `/etc/pam.d`, flags suspicious directives (`pam_permit`, `nullok`, `pam_exec`), lists modules and recent PAM `.so` mtimes.
**Verified:** analyzed PAM config on the target.
**Remaining:**
- [ ] Deepen backdoor detection (known malicious PAM modules / hashes).
- [ ] Optional remediation (revert to known-good PAM config).

## 9 · woodpecker — Default Cred Check ⚠️
**Status:** works. Probes each host over SSH with a default-credential list; flags accepted creds.
**Verified:** ran 10 credential attempts against the target, none accepted (no false positives).
**Remaining:**
- [ ] **Bigger default-password list.**
- [ ] Extend beyond SSH to the services in the README (SMB/FTP, HTTP/WordPress/Gitea, RDP/WinRM/LDAP, SMTP/IMAP/POP3).

## 10 · woof — Patch Misconfigs ⚠️🔒
**Status:** works as a **report** (sshd config, world-writable files, empty-password accounts, `.rhosts`).
**Remaining — needs actual implementation:**
- [ ] Apply/fix mode: fix world-writable perms, lock empty-password accounts, harden sshd.
- [ ] Interactive selection + scheduled-run mode (per README).

## 11 · armadillo — Harden System ⚠️🔒
**Status:** works as a **report** of hardening posture (sysctl, UID-0 accounts, password policy, firewall tooling, listeners).
**Remaining — needs more implementation:**
- [ ] Apply mode: set the sysctl hardening (rp_filter, syncookies, ASLR, disable ip_forward, redirects), enforce password policy.
- [ ] Idempotent + reversible.

## 12 · beaver — Restore Files ⚠️
**Status:** works. Baselines watched files, detects drift by hash, restores the known-good copy.
**Verified:** baseline → tamper → **restored** on the live target.
**Remaining — needs more implementation:**
- [ ] Use chipmunk backups as the source of truth (README: "a wrapper on chipmunk").
- [ ] Broaden watch set (binaries like `id`, `curl`; `/etc/passwd`, `/etc/os-release`) + interactive selection.

## 13 · phoenix — Firewall Tasks ⚠️🔒
**Status:** works as an **audit** (iptables/nft/ufw state, listeners, established outbound).
**Remaining — needs more implementation:**
- [ ] Apply a default-deny + allow-list ruleset, always keeping the current SSH port open (no lockout).
- [ ] Block-all-outbound with a temporary unlock/restore, and the SSH-port-fix task from the README.

## 14 · turtle — Deploy WAF ⚠️🔒
**Status:** works as a **report** of the target's web footprint; `configgen.py`/`logparse.py` present.
**Remaining — needs WAF implementation:**
- [ ] Actual Caddy + Coraza/CRS deploy in front of the web server, driven by `configgen.py`.
- [ ] Verify requests are proxied/filtered.

## 15 · chomp — Deploy EDR ⚠️🔒
**Status:** works as a **detection sweep** (failed logins, listeners, recent SUID, root cron).
**Remaining — needs EDR implementation:**
- [ ] Real detect-and-block agent (the README's core promise).
- [ ] Persistence/health checks + log collection.

---

## Cross-cutting
- [ ] All `.sh` must stay LF (CRLF breaks them on Linux); consider a `.gitattributes` `*.sh text eol=lf`.
- [ ] `meow.sh init()` now `chmod +x`'s all module scripts so a fresh clone is launchable.
- [ ] Static nmap (binary + `nmap-data`) is committed in `Dependencies/` for clone-and-go comp init.
