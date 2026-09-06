# Meow
* This is the distribution engine for our scripts, commands, and tooling.
* `meow.sh` is a **sourceable, OS-aware driver library** — it exposes the driver
  API that every module uses, and dispatches transport per host:
    * **linux**  -> ssh / scp (via `Dependencies/sshpass`)
    * **windows** -> netexec (`nxc`), resolved from `Dependencies/nxc` then `PATH`
* Host inventory record (owned by elephant): `USER IP PASSWORD OS DOMAIN`
  (a missing OS column defaults to linux; DOMAIN `-`/`.` means local auth).
* Driver API:
    * `meow_run "<linux-cmd>" ["<windows-cmd>"]`
    * `meow_deploy <payload.sh> "<linux-remote-cmd>" [log]` — windows hosts run the
      payload's `.ps1` sibling automatically (skipped if none)
    * `meow_push <files...>` / `meow_fetch <remote> <dest>`
    * `meow_win_run|meow_win_put|meow_win_get <user> <ip> <pass> <domain> ...` —
      per-host windows primitives for bespoke flows (used by elephant's roll)
* The interactive launcher lives in `launcher.sh` at the repo root; run custom
  scripts with its `[b] Script` option.

# To Do:
* Establish ssh-keys instead of using sshpass
