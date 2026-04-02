#!/bin/sh
# v9: Rolls passwords, runs a script, output files in better places
# Requires: openssl ssh sshpass wamerican-small
runScript() {
        printf "Script name: "
        read -r script
        log="script_log/${script}_$(date +"%H-%M-%S").out"
        printf "\n"
        while read -r adminUser ip adminPass; do
                printf -- "[----- MEOW: %s -----]\n" "$ip" | tee -a "$log"
                
                sshpass -p "$adminPass" scp -o StrictHostKeyChecking=no "$script" "${adminUser}@${ip}:" 
                sshpass -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "sudo sh "$script"" >> "$log"
        done < passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"
}

runCmd() {
        printf "Command: "
        read cmd;
        log="cmd_log/cmd_$(date +"%H-%M-%S").out"
        printf "Command:\n%s\n\n" "$cmd" >> "$log"
        while read -r adminUser ip adminPass; do
                printf -- "----- MEOW: %s -----\n" "$ip" | tee -a "$log"
                sshpass -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "$cmd" >> "$log"
        done < passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"        
}

genPasswd() {
        grep -E '^[a-z]{3,}$' /usr/share/dict/words | shuf -n 3 | paste -sd '0' -
}
        
initAdmin() {
        printf "If mistaken, Ctrl+c to exit\n"
        printf "Admin:\t\t\t\t"
        read -r adminUser
        printf "Password:\t\t\t"
        read -r adminPass
        while :; do
                rm -f passwd_roll_log/adminUser.txt
                while :; do
                        printf "IP Address (x to stop):\t\t"
                        read -r ip;
                        case "$ip" in
                                x) break ;;
                                *) echo $adminUser $ip $adminPass >> passwd_roll_log/adminUser.txt ;;
                        esac
                done
                
                printf "\n----- adminUser.txt Contents -----\n"
                cat passwd_roll_log/adminUser.txt
                printf '\nConfirm? [y/N]: '
                read isInitAdminGood
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
#       3 random words, "0" sepearated

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
#               * Admin user logs in, once per user, and 'sed's /etc/shadow
#       On each loop, an OK or FAIL is returned
#       UPDATES [-- adminUser.txt --]   

# runCmd() runs premade scripts, custom scripts, and limited arbitrary commands across machines
#       REQUIRES valid [adminUser.txt]


# ----- initAdmin() ----- 
        while true; do
            printf "\nIgnore Admin Init? [y/n]:\t"
            read isFirstRoll
            case "$isFirstRoll" in
                    y) break ;;
                    n) initAdmin 
                       break ;;
                    *) ;;
            esac     
        done

# ----- genUserList() -----
        rm -f passwd_roll_log/users.txt
        while read -r adminUser ip adminPass; do
                printf "Grabbing users from %-15s with %s:%s\n" "$ip" "$adminUser" "$adminPass" 
                sshpass -p "$adminPass" ssh -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "grep -Ev '^#|nologin|false|sync|shutdown|halt|bta|black' /etc/passwd | awk -F: '{print \$1\" $ip\"}'" >> passwd_roll_log/users.txt
        done < passwd_roll_log/adminUser.txt

# ----- assignPasswd() -----
        rm -f passwd_roll_log/clear.txt passwd_roll_log/passwdHashes.txt passwd_roll_log/userHashes.txt passwd_roll_log/adminHashes.txt
        adminUser="$(awk '{print $1; exit}' passwd_roll_log/adminUser.txt)"
        
        while read -r user ip; do
                if [ "$user" != "$adminUser" ] && [ "$user" != "root" ]; then
                        # If password already assigned to user, use previous
                        if grep -q -s -e "^$user " passwd_roll_log/clear.txt; then
                                pass=$(grep -e "^$user " passwd_roll_log/clear.txt | head -n 1 | awk '{print $3}')
                        else
                                pass="$(genPasswd)"
                        fi
                else
                        pass="$(genPasswd)" 
                fi

                # For PCR purposes
                echo "$user $ip $pass" >> passwd_roll_log/clear.txt

                # To modify password
                hashPass=$(openssl passwd -6 "$pass")
                echo "$user $ip $hashPass" >> passwd_roll_log/passwdHashes.txt
        done < passwd_roll_log/users.txt
        
        # Making clear.txt pretty
        column -t passwd_roll_log/clear.txt | awk 'NR>1 && $2!=prev {print ""} {print; prev=$2}' > passwd_roll_log/clear.tmp
        mv passwd_roll_log/clear.tmp passwd_roll_log/clear.txt
        

        grep -v -E "$adminUser" passwd_roll_log/passwdHashes.txt >> passwd_roll_log/userHashes.txt
        grep -E "$adminUser" passwd_roll_log/passwdHashes.txt >> passwd_roll_log/adminHashes.txt

# ----- confirmRoll() -----
        printf -- "\n----- New Passwords -----\n"
        cat passwd_roll_log/clear.txt
        printf "\nExecute? [y/N] "
        read -r confirm
        case $confirm in
                y) ;;
                *) exit ;;
        esac
        
        printf -- "----- Admin Roll -----\n"
        while read -r user ip hash; do
                oldPass="$(grep "$ip" passwd_roll_log/adminUser.txt | awk '{print $3}')"

                # Escaping $ chars
                safe_hash=$(printf '%s\n' "$hash" | sed 's/\$/\\$/g')
                
                # printf "Editing %-12s %-15s with %s:%-35s " "$user" "$ip" "$adminUser" "$oldPass"
                printf "Editing %-12s %-15s " "$user" "$ip"
                if sshpass -p "$oldPass" ssh -n -o StrictHostKeyChecking=no "${user}@${ip}" "sudo sed -i \"s|^$user:[^:]*:|$user:$safe_hash:|\" /etc/shadow" 2>/dev/null; then
                        echo OK
                else
                        echo FAIL
                fi
        done < passwd_roll_log/adminHashes.txt
        
        # Updating adminUser passwords
        grep $adminUser passwd_roll_log/clear.txt | awk '{ print $1, $2, $3 }' > passwd_roll_log/adminUser.tmp
        mv passwd_roll_log/adminUser.tmp passwd_roll_log/adminUser.txt

        printf -- "----- User roll -----\n"
        while read -r user ip hash; do
                adminUser="$(awk '{print $1; exit}' passwd_roll_log/adminUser.txt)"
                adminPass="$(grep "$ip" passwd_roll_log/adminUser.txt | awk '{print $3}')"
                userPass="$(grep "$user" passwd_roll_log/clear.txt | grep "$ip$" | awk '{print $3}')"
                
                # Escaping sensitive chars
                safe_hash=$(printf '%s\n' "$hash" | sed 's/\$/\\$/g')
                
                # printf "Editing %-12s %-15s with %s:%-35s " "$user" "$ip" "$adminUser" "$adminPass"
                printf "Editing %-12s %-15s " "$user" "$ip"
                if sshpass -p "$adminPass" ssh -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "sudo sed -i \"s|^$user:[^:]*:|$user:$safe_hash:|\" /etc/shadow" 2>/dev/null; then
                        echo OK
                else
                        echo FAIL
                fi                
        done < passwd_roll_log/userHashes.txt

        
        # For PCR
        printf "\n----- New Admin Passwords -----\n"
        cat passwd_roll_log/adminUser.txt | column -t
        printf "\n"
}

netEnum() {
        log="net_enum_log/net_enum_$(date +"%H-%M-%S").out"
        touch $log
        printf "\n"
        while read -r adminUser ip adminPass; do
                printf -- "[----- MEOW_NET_ENUM: %s -----]\n" "$ip" | tee -a "$log"
                sshpass -p "$adminPass" scp -o StrictHostKeyChecking=no net_enum.sh "${adminUser}@${ip}:"
                sshpass -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "chmod +x net_enum.sh; ./net_enum.sh 2>&1" >> "$log" 
        done < passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"
}

deployElastic() {
        log="linux_agent_log/linux_agent_log_$(date +"%H-%M-%S").out"
        touch $log
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
                sshpass -p "$adminPass" scp -o StrictHostKeyChecking=no ../logging/linux_agent.sh ../logging/alpine-beats.tar.gz ../logging/rules.conf ../logging/archive_install.sh "${adminUser}@${ip}:"
                sshpass -p "$adminPass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60000 "${adminUser}@${ip}" "sudo sh ~/linux_agent.sh" << EOF 2>>"$log"
$elastic_ip
$kibana_ip
$finger
$elastic_pass
EOF

        done 3< passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log"
}

getBaks() {
        log="baks/baks_log/cmd_$(date +"%H-%M-%S").out"
        touch $log
        while read -r adminUser ip adminPass; do
                printf -- "----- MEOW: %s -----" "$ip" | tee -a "$log"
                latest_bak=$(sshpass -p "$adminPass" ssh -T -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" 'ls -t ~/baks/ 2>/dev/null | head -n 1')
                if [ -z "$latest_bak" ]; then
                        printf " NOT FOUND\n" | tee -a "$log"
                        continue
                
                else
                        printf " FOUND\n" | tee -a "$log"
                fi
                mkdir -p ./baks/"$ip"
                sshpass -p "$adminPass" scp -o StrictHostKeyChecking=no "${adminUser}@${ip}:~/baks/${latest_bak}" "./baks/${ip}/${latest_bak}_$(date +"%H-%M-%S")"
        done < passwd_roll_log/adminUser.txt
        printf "%s\n\n" "$log" 
}

genNmapIps() {
        while true; do
            printf "\nIgnore Admin Init? [y/n]:\t"
            read isFirstRoll
            case "$isFirstRoll" in
                y) 
                        return
                        ;;
                n) 
                        break 
                        ;;
                *)
                        ;;
            esac     
        done
        
        
        while :; do
                rm -f nmap_ips.txt
                while :; do
                        printf "IP Address (x to stop):\t\t"
                        read -r ip;
                        case "$ip" in
                                x) break ;;
                                *) echo $ip >> nmap_ips.txt ;;
                        esac
                done
                
                printf "\n----- nmap_ips.txt Content -----\n"
                cat nmap_ips.txt
                printf '\nConfirm? [y/N]: '
                read isInitNmapIpsGood
                case "$isInitNmapIpsGood" in
                        y) break ;;
                        *) ;;
                esac
        done
        
}

nmap() {
        log="nmap_log/nmap_$(date +"%H-%M-%S").out"
        touch $log
        
        genNmapIps

        while read -r ip ; do
                mkdir -p ./nmap_log/$ip
                printf -- "----- MEOW: %s -----\n" "$ip" | tee -a "$log"
                sudo nmap -Pn -sC -sV -O -p- -oA ./nmap_log/"$ip"/"$ip" "$ip" >> "$log"
        done < nmap_ips.txt
        printf "%s\n\n" "$log"        
}

while true; do
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
    read -r  option
    case "$option" in
        1) 
                rollPasswd
                ;;
        2)
                netEnum
                ;;
        3)
                deployElastic
                ;;
        4)
                printf "DEVELOPING ...\n"
                ;;
        5)
                getBaks
                ;;
        6)
                nmap
                ;;
        a)
                runCmd
                ;;
        b)
                runScript
                ;;
        x) break ;;
        *) ;;
    esac
done
