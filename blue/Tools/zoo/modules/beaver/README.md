# Beaver
* Automatinc common green check restore steps

# Common Tasks
* Restore systemd files and corresponding binaries from backup
* Restore required binaries from backup (i.e. `id`, `curl`)
* Restore common files from backups (`/etc/passwd`, `/etc/os-release`)

# Implementation
* Interactively select files and binaries as `watching` from files in `chipmunk`
    * Checks for these files in the targets, and restores a good version if behaving unexpectedly
    * _(A wrapper on chipmunk essentially)_

