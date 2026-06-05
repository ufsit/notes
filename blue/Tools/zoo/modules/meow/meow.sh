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

genPasswd() {
        grep -E '^[a-z]{3,}$' "$DEPS/words" | shuf -n 3 | paste -sd '0' -
}

initAdmin() {
        printf "If mistaken, Ctrl+c to exit\n"
        printf "Admin:\t\t\t\t"
        read -r adminUser
        printf "Password:\t\t\t"
        read -r adminPass
        while :; do
                rm -f ../elephant/passwd_roll_log/adminUser.txt
                while :; do
                        printf "IP Address (x to stop):\t\t"
                        read -r ip
                        case "$ip" in
                                x) break ;;
                                *) printf '%s %s %s\n' "$adminUser" "$ip" "$adminPass" >> ../elephant/passwd_roll_log/adminUser.txt ;;
                        esac
                done

                printf "\n----- adminUser.txt Contents -----\n"
                cat ../elephant/passwd_roll_log/adminUser.txt
                printf '\nConfirm? [y/N]: '
                read -r isInitAdminGood
                case "$isInitAdminGood" in
                        y) break ;;
                        *) ;;
                esac
        done
}

rollPasswd() {
# Goal: repeated password rolling for Linux systems

# initAdmin() is a simple text generator for the start of comp when one admin has the same password
#       across the network. It will output the following content in the format: USER IP PASSWORD.
#       For subsequent runs, this function must be ignored, which will be the default case.
#       RETURNS [-- adminUser.txt --]: admin user and password for every host; MUST be up-to-date

# genPasswd() generates passphrases from a standard dictionary in *nix systems:
#       3 random words, "0" separated

# genUserList() loops through [adminUser.txt] to login and extract /etc/passwd for a list of users
#       RETURNS [-- users.txt --]       list of users in every host

# assignPasswd() assigns passwords to every user with the following rules:
#       * nonAdmin users get the same passwords if they exist across different machines
#       * Admin users get different passwords
#       RETURNS [-- clear.txt --]        USER IP CLEAR_TEXT_PASSWORD, all users, source of truth
#               [-- passwdHashes.txt --] USER IP HASHED_PASSWORD, all users, source of truth
#               [-- userHashes.txt --]   USER IP HASHED_PASSWORD, non-admin users
#               [-- adminHashes.txt --]  USER IP HASHED_PASSWORD, admin users

# confirmRoll() rolls passwords in two waves:
#       1. admin users, using adminHashes.txt
#               * Admin user logs in, changes its own password
#       2. non-admin users, using userHashes.txt
#               * Admin user logs in, once per user, and changes via usermod -p
#       On each loop, an OK or FAIL is returned
#       UPDATES [-- adminUser.txt --]

# runCmd() runs premade scripts, custom scripts, and limited arbitrary commands across machines
#       REQUIRES valid [adminUser.txt]


# ----- initAdmin() -----
        while true; do
            printf "\nIgnore Admin Init? [y/n]:\t"
            read -r isFirstRoll
            case "$isFirstRoll" in
                    y) break ;;
                    n) initAdmin
                       break ;;
                    *) ;;
            esac
        done

# ----- genUserList() -----
        rm -f ../elephant/passwd_roll_log/users.txt
        while read -r adminUser ip adminPass; do
                printf "Grabbing users from %-15s with %s:%s\n" "$ip" "$adminUser" "$adminPass"
                "$DEPS/sshpass" -p "$adminPass" ssh -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "grep -Ev '^#|nologin|false|sync|shutdown|halt|bta|black' /etc/passwd | awk -F: '{print \$1\" $ip\"}'" >> ../elephant/passwd_roll_log/users.txt
        done < ../elephant/passwd_roll_log/adminUser.txt

# ----- assignPasswd() -----
        rm -f ../elephant/passwd_roll_log/clear.txt ../elephant/passwd_roll_log/passwdHashes.txt ../elephant/passwd_roll_log/userHashes.txt ../elephant/passwd_roll_log/adminHashes.txt
        adminUser="$(awk '{print $1; exit}' ../elephant/passwd_roll_log/adminUser.txt)"

        while read -r user ip; do
                if [ "$user" != "$adminUser" ] && [ "$user" != "root" ]; then
                        if grep -q -s "^$user " ../elephant/passwd_roll_log/clear.txt; then
                                pass=$(awk -v u="$user" '$1==u {print $3; exit}' ../elephant/passwd_roll_log/clear.txt)
                        else
                                pass="$(genPasswd)"
                        fi
                else
                        pass="$(genPasswd)"
                fi

                echo "$user $ip $pass" >> ../elephant/passwd_roll_log/clear.txt
                hashPass=$(openssl passwd -6 "$pass")
                echo "$user $ip $hashPass" >> ../elephant/passwd_roll_log/passwdHashes.txt
        done < ../elephant/passwd_roll_log/users.txt

        # Making clear.txt pretty
        column -t ../elephant/passwd_roll_log/clear.txt | awk 'NR>1 && $2!=prev {print ""} {print; prev=$2}' > ../elephant/passwd_roll_log/clear.tmp
        mv ../elephant/passwd_roll_log/clear.tmp ../elephant/passwd_roll_log/clear.txt

        grep -v "^$adminUser " ../elephant/passwd_roll_log/passwdHashes.txt > ../elephant/passwd_roll_log/userHashes.txt
        grep "^$adminUser " ../elephant/passwd_roll_log/passwdHashes.txt > ../elephant/passwd_roll_log/adminHashes.txt

# ----- confirmRoll() -----
        printf -- "\n----- New Passwords -----\n"
        cat ../elephant/passwd_roll_log/clear.txt
        printf "\nExecute? [y/N] "
        read -r confirm
        case $confirm in
                y) ;;
                *) return ;;
        esac

        printf -- "----- Admin Roll -----\n"
        while read -r user ip hash <&3; do
                oldPass="$(awk -v u="$user" -v i="$ip" '$1==u && $2==i {print $3}' ../elephant/passwd_roll_log/adminUser.txt)"
                # This is likely unnecessary for the poor other person, but some versions of openssl add newlines in the hash, so base64 encoding is used so it doesn't freak out between shells (Dont ask how I know... :( )
                hash_b64=$(printf '%s' "$hash" | base64 -w 0)

                printf "Editing %-12s %-15s " "$user" "$ip"
                if "$DEPS/sshpass" -p "$oldPass" ssh -tt -o StrictHostKeyChecking=no "${user}@${ip}" "echo '$oldPass' | sudo -S -p '' usermod -p \"\$(printf '%s' $hash_b64 | base64 -d)\" $user 2>/dev/null" 2>/dev/null; then
                        echo OK
                        # Moved the admin update here since the admin password is needed for the user roll, and this way if the admin roll fails, the user roll won't execute with a broken password list
                        newPass="$(awk -v u="$user" -v i="$ip" '$1==u && $2==i {print $3}' ../elephant/passwd_roll_log/clear.txt)"
                        awk -v u="$user" -v i="$ip" -v p="$newPass" \
                            '$1==u && $2==i {$3=p} {print}' \
                            ../elephant/passwd_roll_log/adminUser.txt > ../elephant/passwd_roll_log/adminUser.tmp
                        mv ../elephant/passwd_roll_log/adminUser.tmp ../elephant/passwd_roll_log/adminUser.txt
                else
                        echo FAIL
                fi
        done 3< ../elephant/passwd_roll_log/adminHashes.txt

        printf -- "----- User roll -----\n"
        while read -r user ip hash <&3; do
                adminUser="$(awk '{print $1; exit}' ../elephant/passwd_roll_log/adminUser.txt)"
                adminPass="$(awk -v i="$ip" '$2==i {print $3; exit}' ../elephant/passwd_roll_log/adminUser.txt)"
                hash_b64=$(printf '%s' "$hash" | base64 -w 0)

                printf "Editing %-12s %-15s " "$user" "$ip"
                if "$DEPS/sshpass" -p "$adminPass" ssh -tt -o StrictHostKeyChecking=no "${adminUser}@${ip}" "echo '$adminPass' | sudo -S -p '' usermod -p \"\$(printf '%s' $hash_b64 | base64 -d)\" $user 2>/dev/null" 2>/dev/null; then
                        echo OK
                else
                        echo FAIL
                fi
        done 3< ../elephant/passwd_roll_log/userHashes.txt

        # For PCR
        printf "\n----- New Admin Passwords -----\n"
        column -t ../elephant/passwd_roll_log/adminUser.txt
        printf "\n"
}

netEnum() {
        log="../nematode/net_enum_log/net_enum_$(date +"%H-%M-%S").out"
        touch "$log"
        printf "\n"
        while read -r adminUser ip adminPass; do
                printf -- "[----- MEOW_NET_ENUM: %s -----]\n" "$ip" | tee -a "$log"
                "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "$DEPS/net_enum.sh" "${adminUser}@${ip}:"
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
                "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no "$DEPS/linux_agent.sh" "$DEPS/alpine-beats.tar.gz" "$DEPS/rules.conf" "$DEPS/archive_install.sh" "${adminUser}@${ip}:"
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
        chmod +x "$DEPS/sshpass" "$DEPS/nmap" "$DEPS/net_enum.sh" "$DEPS/linux_agent.sh" "$DEPS/archive_install.sh" 2>/dev/null
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
        1) rollPasswd ;;
        2) netEnum ;;
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
