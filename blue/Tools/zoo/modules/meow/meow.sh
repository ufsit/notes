#!/bin/bash
# meow: OS-aware connector/comm-driver LIBRARY.
#   - Sourced by module scripts (and launcher.sh); exposes the meow_* driver functions.
#   - Per host it dispatches transport: SSH/scp for linux, netexec (nxc) for windows.
#   - The interactive launcher lives in launcher.sh at the repo root.
# Modules push payloads/commands through the meow_* functions, so all transport
# lives in exactly one place.
#
# Host inventory record (owned by elephant):  USER IP PASSWORD OS DOMAIN
#   OS     = linux | windows            (missing column defaults to linux)
#   DOMAIN = - for linux / local-auth windows, else a domain name

MEOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS="${DEPS:-$MEOW_DIR/../../Dependencies}"
HOSTS="${HOSTS:-$MEOW_DIR/../elephant/passwd_roll_log/adminUser.txt}"
SSH_OPTS="-o StrictHostKeyChecking=no"

# Resolve netexec: bundled Dependencies/nxc first, else PATH (uv/pipx install).
NXC="$DEPS/nxc"; [ -x "$NXC" ] || NXC="$(command -v nxc 2>/dev/null)"

# ============================================================================
# Shared helpers
# ============================================================================

# Path to the host inventory (USER IP PASSWORD OS DOMAIN), owned by elephant.
meow_hosts() { printf '%s\n' "$HOSTS"; }

# Generate a passphrase: 3 dictionary words, "0"-separated.
genPasswd() { grep -E '^[a-z]{3,}$' "$DEPS/words" | shuf -n 3 | paste -sd '0' -; }

# meow_require_hosts: fail loudly if no host list exists yet.
meow_require_hosts() {
        if [ ! -s "$HOSTS" ]; then
                printf "meow: no hosts in %s (run Password Roll / elephant initAdmin first)\n" "$HOSTS" >&2
                return 1
        fi
}

# ============================================================================
# Transport backends. meow_win_* are public primitives for bespoke windows flows.
# ============================================================================

_meow_ssh_run() {  # user ip pass cmd
        "$DEPS/sshpass" -p "$3" ssh -T -n $SSH_OPTS "${1}@${2}" "$4"
}
_meow_ssh_put() {  # user ip pass file...
        _u=$1 _ip=$2 _p=$3; shift 3
        "$DEPS/sshpass" -p "$_p" scp $SSH_OPTS "$@" "${_u}@${_ip}:"
}
_meow_ssh_get() {  # user ip pass remote dest
        "$DEPS/sshpass" -p "$3" scp $SSH_OPTS "${1}@${2}:$4" "$5"
}

# netexec auth flag from a DOMAIN value ("-"/"."/empty => local admin).
_meow_nxc_auth() { case "${1:-}" in ''|-|.) printf -- '--local-auth' ;; *) printf -- '-d %s' "$1" ;; esac; }

# Ensure nxc is available before touching a windows host.
_meow_nxc_ok() {
        [ -n "$NXC" ] && return 0
        printf "meow: netexec (nxc) not found -- run ./setup.sh or put nxc on PATH; skipping windows host\n" >&2
        return 1
}
meow_win_run() {  # user ip pass domain cmd
        _meow_nxc_ok || return 1
        "$NXC" smb "$2" -u "$1" -p "$3" $(_meow_nxc_auth "$4") -x "$5"
}
meow_win_put() {  # user ip pass domain localfile [remote]
        _meow_nxc_ok || return 1
        _rem="${6:-\\Windows\\Temp\\$(basename "$5")}"
        "$NXC" smb "$2" -u "$1" -p "$3" $(_meow_nxc_auth "$4") --put-file "$5" "$_rem"
}
meow_win_get() {  # user ip pass domain remote localdir
        _meow_nxc_ok || return 1
        "$NXC" smb "$2" -u "$1" -p "$3" $(_meow_nxc_auth "$4") --get-file "$5" "$6"
}

# Deploy a payload to one windows host: use the .ps1 sibling of the .sh payload
# (or the .ps1 itself), upload to Temp, run it, then clean up. Skip if none.
_meow_win_deploy() {  # user ip pass domain payload
        _ps="$5"; [ "${_ps##*.}" = sh ] && _ps="${5%.sh}.ps1"
        if [ -z "$5" ] || [ ! -f "$_ps" ]; then
                printf "  (skip %s: no windows payload)\n" "$2"; return 0
        fi
        _rem="C:\\Windows\\Temp\\$(basename "$_ps")"
        meow_win_put "$1" "$2" "$3" "$4" "$_ps" "\\Windows\\Temp\\$(basename "$_ps")" || return 1
        meow_win_run "$1" "$2" "$3" "$4" "powershell -ExecutionPolicy Bypass -File $_rem"
        meow_win_run "$1" "$2" "$3" "$4" "cmd /c del $_rem" >/dev/null 2>&1
}

# ============================================================================
# Driver API (called by module scripts)
# ============================================================================

# meow_run "<linux-cmd>" ["<windows-cmd>"]: run a command on every host.
#   linux hosts get <linux-cmd> over ssh; windows hosts get <windows-cmd> over
#   nxc (skipped if <windows-cmd> is omitted).
meow_run() {
        meow_require_hosts || return 1
        _lcmd="$1"; _wcmd="$2"
        while read -r adminUser ip adminPass os domain; do
                [ -z "$ip" ] && continue
                printf -- "----- MEOW: %s (%s) -----\n" "$ip" "${os:-linux}"
                case "${os:-linux}" in
                        windows) if [ -n "$_wcmd" ]; then
                                        meow_win_run "$adminUser" "$ip" "$adminPass" "$domain" "$_wcmd"
                                 else printf "  (skip %s: no windows command)\n" "$ip"; fi ;;
                        *)       _meow_ssh_run "$adminUser" "$ip" "$adminPass" "$_lcmd" ;;
                esac
        done < "$HOSTS"
}

# meow_deploy <payload> "<linux-remote-cmd>" [logfile]:
#   linux  -> scp payload to ~, run <linux-remote-cmd>, tee to logfile.
#   windows-> run the payload's .ps1 sibling via nxc (skip if none).
meow_deploy() {
        meow_require_hosts || return 1
        _payload="$1"; _rcmd="$2"; _log="$3"
        if [ -n "$_log" ]; then mkdir -p "$(dirname "$_log")"; : > "$_log"; fi
        while read -r adminUser ip adminPass os domain; do
                [ -z "$ip" ] && continue
                {
                        printf -- "[----- MEOW: %s (%s) -----]\n" "$ip" "${os:-linux}"
                        case "${os:-linux}" in
                                windows) _meow_win_deploy "$adminUser" "$ip" "$adminPass" "$domain" "$_payload" 2>&1 ;;
                                *)       [ -n "$_payload" ] && _meow_ssh_put "$adminUser" "$ip" "$adminPass" "$_payload" >/dev/null 2>&1
                                         _meow_ssh_run "$adminUser" "$ip" "$adminPass" "$_rcmd" 2>&1 ;;
                        esac
                } | { if [ -n "$_log" ]; then tee -a "$_log"; else cat; fi; }
        done < "$HOSTS"
}

# meow_push <file>...: copy local files to each host (home dir / Temp).
meow_push() {
        meow_require_hosts || return 1
        while read -r adminUser ip adminPass os domain; do
                [ -z "$ip" ] && continue
                printf -- "----- MEOW push -> %s (%s) -----\n" "$ip" "${os:-linux}"
                case "${os:-linux}" in
                        windows) for _f in "$@"; do meow_win_put "$adminUser" "$ip" "$adminPass" "$domain" "$_f"; done ;;
                        *)       _meow_ssh_put "$adminUser" "$ip" "$adminPass" "$@" ;;
                esac
        done < "$HOSTS"
}

# meow_fetch "<remote-path>" <local-dir>: pull files from each host into <local-dir>/<ip>/.
meow_fetch() {
        meow_require_hosts || return 1
        _remote="$1"; _dest="$2"
        while read -r adminUser ip adminPass os domain; do
                [ -z "$ip" ] && continue
                mkdir -p "$_dest/$ip"
                printf -- "----- MEOW fetch <- %s (%s) -----\n" "$ip" "${os:-linux}"
                case "${os:-linux}" in
                        windows) meow_win_get "$adminUser" "$ip" "$adminPass" "$domain" "$_remote" "$_dest/$ip/" ;;
                        *)       _meow_ssh_get "$adminUser" "$ip" "$adminPass" "$_remote" "$_dest/$ip/" 2>/dev/null ;;
                esac
        done < "$HOSTS"
}

# This file is a library. If executed directly, point the operator at the launcher.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
        printf 'meow.sh is a driver library; run launcher.sh at the repo root instead.\n' >&2
        exit 1
fi
