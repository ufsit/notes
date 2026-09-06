#!/bin/bash
# launcher: interactive entry point for the zoo toolkit.
#   Sources meow's driver library, then runs each module orchestrator from a menu.
#   meow.sh is a pure library now; this file is the only interactive surface.

LAUNCHER_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES="$LAUNCHER_DIR/modules"

# Load the meow driver library (meow_run / meow_deploy / meow_require_hosts ...).
. "$MODULES/meow/meow.sh"

mod() { m="$1"; shift; "$MODULES/$m" "$@"; }   # run a module orchestrator by relative path

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
                "$MODULES/elephant/passwd_roll_log" \
                "$MODULES/nematode/net_enum_log" \
                "$MODULES/elk/linux_agent_log" \
                "$MODULES/chipmunk/baks/baks_log" \
                "$MODULES/hawk/nmap_log" \
                "$MODULES/woof/woof_log" \
                "$MODULES/meerkat/meerkat_log" \
                "$MODULES/lynx/lynx_log" \
                "$MODULES/woodpecker/woodpecker_log" \
                "$MODULES/armadillo/armadillo_log" \
                "$MODULES/beaver/beaver_log" \
                "$MODULES/phoenix/phoenix_log" \
                "$MODULES/suricata/suricata_log" \
                "$MODULES/chomp/chomp_log"
        chmod +x "$DEPS/sshpass" "$DEPS/nmap" "$DEPS/nxc" "$MODULES"/*/*.sh 2>/dev/null
}

clean_up() {
        rm -rf \
                "$MODULES"/elephant/passwd_roll_log/* \
                "$MODULES"/nematode/net_enum_log/* \
                "$MODULES"/elk/linux_agent_log/* \
                "$MODULES"/chipmunk/baks/baks_log/* \
                "$MODULES"/hawk/nmap_log/* \
                "$MODULES"/woof/woof_log/* \
                "$MODULES"/meerkat/meerkat_log/* \
                "$MODULES"/lynx/lynx_log/* \
                "$MODULES"/woodpecker/woodpecker_log/* \
                "$MODULES"/armadillo/armadillo_log/* \
                "$MODULES"/beaver/beaver_log/* \
                "$MODULES"/phoenix/phoenix_log/* \
                "$MODULES"/suricata/suricata_log/* \
                "$MODULES"/chomp/chomp_log/* 2>/dev/null
}

run_menu() {
        while true; do
                init
                printf "\n~~~~~ Welcome to meow! ~~~~~~\n"
                printf "[0]  Setup Hosts          (elephant)\n"
                printf "[1]  Password Roll        (elephant)\n"
                printf "[2]  Network Enum         (nematode)\n"
                printf "[3]  Deploy Elastic Agent (elk)\n"
                printf "[4]  Deploy Suricata      (suricata)\n"
                printf "[5]  Get Backups          (chipmunk)\n"
                printf "[6]  Service Health       (meerkat)\n"
                printf "[7]  PAM Audit            (lynx)\n"
                printf "[8]  Default Cred Check   (woodpecker)\n"
                printf "[9]  Patch Misconfigs     (woof)\n"
                printf "[10] Harden System        (armadillo)\n"
                printf "[11] Restore Files        (beaver)\n"
                printf "[12] Firewall Tasks       (phoenix)\n"
                printf "[13] Deploy WAF           (turtle)\n"
                printf "[14] Deploy EDR           (chomp)\n"
                printf "\n[a] Command   [b] Script   [x] Exit\n"
                printf "Option: "
                read -r option
                case "$option" in
                        0)  mod elephant/elephant.sh init ;;
                        1)  mod elephant/elephant.sh ;;
                        2)  mod nematode/nematode.sh ;;
                        3)  mod elk/elk.sh ;;
                        4)  mod suricata/suricata.sh ;;
                        5)  mod chipmunk/chipmunk.sh ;;
                        6)  mod meerkat/meerkat.sh ;;
                        7)  mod lynx/lynx.sh ;;
                        8)  mod woodpecker/woodpecker.sh ;;
                        9)  mod woof/woof.sh ;;
                        10) mod armadillo/armadillo.sh ;;
                        11) mod beaver/beaver.sh ;;
                        12) mod phoenix/phoenix.sh ;;
                        13) mod turtle/turtle.sh ;;
                        14) mod chomp/chomp.sh ;;
                        a)  meow_cmd ;;
                        b)  meow_script ;;
                        x)  clean_up; break ;;
                        *)  ;;
                esac
        done
}

run_menu
