#!/bin/bash
# meow v11: connector/comm-driver LIBRARY + launcher.
#   - When sourced by a module script, exposes the meow_* driver functions.
#   - When executed directly, presents the launcher menu that runs each module.
# Every module script sources this file and pushes its payload/commands through
# the meow_* functions, so the SSH/scp transport lives in exactly one place.

# Anchor to THIS file's location (works whether sourced or executed).
MEOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS="$MEOW_DIR/../../Dependencies"
HOSTS="$MEOW_DIR/../elephant/passwd_roll_log/adminUser.txt"
SSH_OPTS="-o StrictHostKeyChecking=no"

# ============================================================================
# Driver library  (sourced by module scripts)
# ============================================================================

# Path to the host list (USER IP PASSWORD), owned by elephant.
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

# meow_run "<remote-cmd>": run a command on every host, stream output.
meow_run() {
        meow_require_hosts || return 1
        _cmd="$1"
        while read -r adminUser ip adminPass; do
                [ -z "$ip" ] && continue
                printf -- "----- MEOW: %s -----\n" "$ip"
                "$DEPS/sshpass" -p "$adminPass" ssh -T -n $SSH_OPTS "${adminUser}@${ip}" "$_cmd"
        done < "$HOSTS"
}

# meow_deploy <local_payload> "<remote-cmd>" [logfile]:
#   scp the payload to each host, run <remote-cmd> there, tee output to logfile.
meow_deploy() {
        meow_require_hosts || return 1
        _payload="$1"; _rcmd="$2"; _log="$3"
        if [ -n "$_log" ]; then mkdir -p "$(dirname "$_log")"; : > "$_log"; fi
        while read -r adminUser ip adminPass; do
                [ -z "$ip" ] && continue
                if [ -n "$_log" ]; then
                        printf -- "[----- MEOW: %s -----]\n" "$ip" | tee -a "$_log"
                else
                        printf -- "[----- MEOW: %s -----]\n" "$ip"
                fi
                [ -n "$_payload" ] && "$DEPS/sshpass" -p "$adminPass" scp $SSH_OPTS "$_payload" "${adminUser}@${ip}:" >/dev/null 2>&1
                if [ -n "$_log" ]; then
                        "$DEPS/sshpass" -p "$adminPass" ssh -T -n $SSH_OPTS "${adminUser}@${ip}" "$_rcmd" 2>&1 | tee -a "$_log"
                else
                        "$DEPS/sshpass" -p "$adminPass" ssh -T -n $SSH_OPTS "${adminUser}@${ip}" "$_rcmd"
                fi
        done < "$HOSTS"
}

# meow_push <file>...: copy local files to each host's home.
meow_push() {
        meow_require_hosts || return 1
        while read -r adminUser ip adminPass; do
                [ -z "$ip" ] && continue
                printf -- "----- MEOW push -> %s -----\n" "$ip"
                "$DEPS/sshpass" -p "$adminPass" scp $SSH_OPTS "$@" "${adminUser}@${ip}:"
        done < "$HOSTS"
}

# meow_fetch "<remote-path>" <local-dir>: pull files from each host into <local-dir>/<ip>/.
meow_fetch() {
        meow_require_hosts || return 1
        _remote="$1"; _dest="$2"
        while read -r adminUser ip adminPass; do
                [ -z "$ip" ] && continue
                mkdir -p "$_dest/$ip"
                printf -- "----- MEOW fetch <- %s -----\n" "$ip"
                "$DEPS/sshpass" -p "$adminPass" scp $SSH_OPTS "${adminUser}@${ip}:$_remote" "$_dest/$ip/" 2>/dev/null
        done < "$HOSTS"
}

# ============================================================================
# Launcher  (only when executed directly, not when sourced)
# ============================================================================

mod() { "$MEOW_DIR/../$1"; }   # run a module orchestrator by relative path

meow_cmd() {   # [a] ad-hoc command
        printf "Command: "; read -r cmd; printf "\n"
        meow_run "$cmd"
}

meow_script() {   # [b] ad-hoc script
        printf "Local script path: "; read -r script
        printf "Remote command [sh ~/%s]: " "$(basename "$script")"; read -r rcmd
        [ -z "$rcmd" ] && rcmd="sh ~/$(basename "$script")"
        meow_deploy "$script" "$rcmd"
}

init() {
        mkdir -p \
                "$MEOW_DIR/../elephant/passwd_roll_log" \
                "$MEOW_DIR/../nematode/net_enum_log" \
                "$MEOW_DIR/../elk/linux_agent_log" \
                "$MEOW_DIR/../chipmunk/baks/baks_log" \
                "$MEOW_DIR/../hawk/nmap_log" \
                "$MEOW_DIR/../woof/woof_log" \
                "$MEOW_DIR/../meerkat/meerkat_log" \
                "$MEOW_DIR/../lynx/lynx_log" \
                "$MEOW_DIR/../woodpecker/woodpecker_log" \
                "$MEOW_DIR/../armadillo/armadillo_log" \
                "$MEOW_DIR/../beaver/beaver_log" \
                "$MEOW_DIR/../phoenix/phoenix_log" \
                "$MEOW_DIR/../suricata/suricata_log" \
                "$MEOW_DIR/../chomp/chomp_log"
        chmod +x "$DEPS/sshpass" "$DEPS/nmap" "$MEOW_DIR"/../*/*.sh 2>/dev/null
}

clean_up() {
        rm -rf \
                "$MEOW_DIR"/../elephant/passwd_roll_log/* \
                "$MEOW_DIR"/../nematode/net_enum_log/* \
                "$MEOW_DIR"/../elk/linux_agent_log/* \
                "$MEOW_DIR"/../chipmunk/baks/baks_log/* \
                "$MEOW_DIR"/../hawk/nmap_log/* \
                "$MEOW_DIR"/../woof/woof_log/* \
                "$MEOW_DIR"/../meerkat/meerkat_log/* \
                "$MEOW_DIR"/../lynx/lynx_log/* \
                "$MEOW_DIR"/../woodpecker/woodpecker_log/* \
                "$MEOW_DIR"/../armadillo/armadillo_log/* \
                "$MEOW_DIR"/../beaver/beaver_log/* \
                "$MEOW_DIR"/../phoenix/phoenix_log/* \
                "$MEOW_DIR"/../suricata/suricata_log/* \
                "$MEOW_DIR"/../chomp/chomp_log/* 2>/dev/null
}

run_menu() {
        while true; do
                init
                printf "\n~~~~~ Welcome to meow! ~~~~~~\n"
                printf "[1]  Password Roll        (elephant)\n"
                printf "[2]  Network Enum         (nematode)\n"
                printf "[3]  Deploy Elastic Agent (elk)\n"
                printf "[4]  Deploy Suricata      (suricata)\n"
                printf "[5]  Get Backups          (chipmunk)\n"
                printf "[6]  Nmap Scan            (hawk)\n"
                printf "[7]  Service Health       (meerkat)\n"
                printf "[8]  PAM Audit            (lynx)\n"
                printf "[9]  Default Cred Check   (woodpecker)\n"
                printf "[10] Patch Misconfigs     (woof)\n"
                printf "[11] Harden System        (armadillo)\n"
                printf "[12] Restore Files        (beaver)\n"
                printf "[13] Firewall Tasks       (phoenix)\n"
                printf "[14] Deploy WAF           (turtle)\n"
                printf "[15] Deploy EDR           (chomp)\n"
                printf "\n[a] Command   [b] Script   [x] Exit\n"
                printf "Option: "
                read -r option
                case "$option" in
                        1)  mod elephant/elephant.sh ;;
                        2)  mod nematode/nematode.sh ;;
                        3)  mod elk/elk.sh ;;
                        4)  mod suricata/suricata.sh ;;
                        5)  mod chipmunk/chipmunk.sh ;;
                        6)  mod hawk/hawk.sh ;;
                        7)  mod meerkat/meerkat.sh ;;
                        8)  mod lynx/lynx.sh ;;
                        9)  mod woodpecker/woodpecker.sh ;;
                        10) mod woof/woof.sh ;;
                        11) mod armadillo/armadillo.sh ;;
                        12) mod beaver/beaver.sh ;;
                        13) mod phoenix/phoenix.sh ;;
                        14) mod turtle/turtle.sh ;;
                        15) mod chomp/chomp.sh ;;
                        a)  meow_cmd ;;
                        b)  meow_script ;;
                        x)  clean_up; break ;;
                        *)  ;;
                esac
        done
}

# Run the menu only when executed directly (sourcing just loads the library).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
        run_menu
fi
