#!/bin/bash
# v10: Remodeled logging system, added dependencies, deprecated script/cmd logs
DEPS="$(dirname "$0")/../../Dependencies"

runScript() {
        printf "Script name: "
        read -r script
        printf "\n"
        while read -r adminUser ip adminPass; do
                printf -- "[----- MEOW: %s -----]\n" "$ip"
                "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "$script" "${adminUser}@${ip}:"
                "$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "sudo sh $script"
        done < ../elephant/passwd_roll_log/adminUser.txt
}

runCmd() {
        printf "Command: "
        read -r cmd
        printf "Command:\n%s\n\n" "$cmd"
        while read -r adminUser ip adminPass; do
                printf -- "----- MEOW: %s -----\n" "$ip"
                "$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "$cmd"
        done < ../elephant/passwd_roll_log/adminUser.txt
}

netEnum() {
        log="../nematode/net_enum_log/net_enum_$(date +"%H-%M-%S").out"
        touch "$log"
        printf "\n"
        while read -r adminUser ip adminPass; do
                printf -- "[----- MEOW_NET_ENUM: %s -----]\n" "$ip" | tee -a "$log"
                "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "../nematode/net_enum.sh" "${adminUser}@${ip}:"
                "$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "chmod +x net_enum.sh; ./net_enum.sh 2>&1" >> "$log"
        done < ../elephant/passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"
}

deployElastic() {
        log="../elk/linux_agent_log/linux_agent_log_$(date +"%H-%M-%S").out"
        touch "$log"
        printf "\n"
        printf "Elastic Server ip: "
        read -r elastic_ip
        printf "Kibana Server ip: "
        read -r kibana_ip
        printf "CA Fingerprint: "
        read -r finger
        printf "Elastic Password: "
        read -r elastic_pass
        while read -r adminUser ip adminPass <&3; do
                printf -- "[----- MEOW_ELASTIC_AGENT: %s; TIME: %s -----]\n" "$ip" "$(date +"%H-%M-%S")" | tee -a "$log"
                "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "../elk/linux_agent.sh" "../elk/alpine-beats.tar.gz" "../elk/rules.conf" "../elk/archive_install.sh" "${adminUser}@${ip}:"
                "$DEPS/sshpass" -p "$adminPass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60000 "${adminUser}@${ip}" "sudo sh ~/linux_agent.sh" << EOF 2>>"$log"
$elastic_ip
$kibana_ip
$finger
$elastic_pass
EOF

        done 3< ../elephant/passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"
}

getBaks() {
        log="../chipmunk/baks/baks_log/cmd_$(date +"%H-%M-%S").out"
        touch "$log"
        while read -r adminUser ip adminPass; do
                printf -- "----- MEOW: %s -----" "$ip" | tee -a "$log"
                latest_bak=$("$DEPS/sshpass" -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" 'ls -t ~/baks/ 2>/dev/null | head -n 1')
                if [ -z "$latest_bak" ]; then
                        printf " NOT FOUND\n" | tee -a "$log"
                        continue
                else
                        printf " FOUND\n" | tee -a "$log"
                fi
                mkdir -p ../chipmunk/baks/"$ip"
                "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "${adminUser}@${ip}:~/baks/${latest_bak}" "../chipmunk/baks/${ip}/${latest_bak}_$(date +"%H-%M-%S")"
        done < ../elephant/passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"
}

genNmapIps() {
        while true; do
            printf "\nIgnore Admin Init? [y/n]:\t"
            read -r isFirstRoll
            case "$isFirstRoll" in
                y) return ;;
                n) break ;;
                *) ;;
            esac
        done

        while :; do
                rm -f nmap_ips.txt
                while :; do
                        printf "IP Address (x to stop):\t\t"
                        read -r ip
                        case "$ip" in
                                x) break ;;
                                *) echo "$ip" >> nmap_ips.txt ;;
                        esac
                done

                printf "\n----- nmap_ips.txt Content -----\n"
                cat nmap_ips.txt
                printf '\nConfirm? [y/N]: '
                read -r isInitNmapIpsGood
                case "$isInitNmapIpsGood" in
                        y) break ;;
                        *) ;;
                esac
        done
}

nmap() {
        log="../hawk/nmap_log/nmap_$(date +"%H-%M-%S").out"
        touch "$log"

        genNmapIps

        while read -r ip; do
                mkdir -p ../hawk/nmap_log/"$ip"
                printf -- "----- MEOW: %s -----\n" "$ip" | tee -a "$log"
                sudo "$DEPS/nmap" --datadir "$DEPS/nmap-data" -Pn -sC -sV -O -p- -oA ../hawk/nmap_log/"$ip"/"$ip" "$ip" >> "$log"
        done < nmap_ips.txt
        printf "%s\n\n" "$log"
}

init() {
        mkdir -p ../elephant/passwd_roll_log ../elk/linux_agent_log ../chipmunk/baks/baks_log ../hawk/nmap_log ../woof/woof_log ../nematode/net_enum_log
        touch nmap_ips.txt
        chmod +x "$DEPS/sshpass" "$DEPS/nmap" "../nematode/net_enum.sh" "../elk/linux_agent.sh" "../elk/archive_install.sh" 2>/dev/null
}

clean_up() {
        rm -rf ../elephant/passwd_roll_log/* ../elk/linux_agent_log/* ../chipmunk/baks/baks_log/* ../hawk/nmap_log/* ../woof/woof_log/* ../nematode/net_enum_log/*
}

while true; do
    init
    printf "~~~~~ Welcome to meow! ~~~~~~\n"
    printf "[1] Password Roll\n"
    printf "[2] Network Enum\n"
    printf "[3] Deploy Elastic Agent\n"
    printf "[4] Deploy Suricata\n"
    printf "[5] Get Backups\n"
    printf "[6] Nmap Scan\n"
    printf "\n"
    printf "[a] Command\n"
    printf "[b] Script\n"
    printf "[x] Exit\n"
    printf "Option: "
    read -r option
    case "$option" in
        1) ../elephant/elephant.sh ;;
        2) ../nematode/net_enum.sh ;;
        3) deployElastic ;;
        4) printf "DEVELOPING ...\n" ;;
        5) getBaks ;;
        6) nmap ;;
        a) runCmd ;;
        b) runScript ;;
        x) clean_up; break ;;
        *) ;;
    esac
done
