#!/bin/bash
# Elephant: generation and management of user passwords across hosts.
# Sources meow's driver library for shared helpers ($DEPS, genPasswd, host list).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
LOG="$HERE/passwd_roll_log"
mkdir -p "$LOG"

initAdmin() {
        printf "If mistaken, Ctrl+c to exit\n"
        printf "Admin:\t\t\t\t"
        read -r adminUser
        printf "Password:\t\t\t"
        read -r adminPass
        while :; do
                rm -f "$LOG/adminUser.txt"
                while :; do
                        printf "IP Address (x to stop):\t\t"
                        read -r ip
                        case "$ip" in
                                x) break ;;
                                *) printf '%s %s %s\n' "$adminUser" "$ip" "$adminPass" >> "$LOG/adminUser.txt" ;;
                        esac
                done

                printf "\n----- adminUser.txt Contents -----\n"
                cat "$LOG/adminUser.txt"
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
        rm -f "$LOG/users.txt"
        while read -r adminUser ip adminPass; do
                printf "Grabbing users from %-15s with %s:%s\n" "$ip" "$adminUser" "$adminPass"
                "$DEPS/sshpass" -p "$adminPass" ssh -n -o StrictHostKeyChecking=no "${adminUser}@${ip}" "grep -Ev '^#|nologin|false|sync|shutdown|halt|bta|black' /etc/passwd | awk -F: '{print \$1\" $ip\"}'" >> "$LOG/users.txt"
        done < "$LOG/adminUser.txt"

# ----- assignPasswd() -----
        rm -f "$LOG/clear.txt" "$LOG/passwdHashes.txt" "$LOG/userHashes.txt" "$LOG/adminHashes.txt"
        adminUser="$(awk '{print $1; exit}' "$LOG/adminUser.txt")"

        while read -r user ip; do
                if [ "$user" != "$adminUser" ] && [ "$user" != "root" ]; then
                        if grep -q -s "^$user " "$LOG/clear.txt"; then
                                pass=$(awk -v u="$user" '$1==u {print $3; exit}' "$LOG/clear.txt")
                        else
                                pass="$(genPasswd)"
                        fi
                else
                        pass="$(genPasswd)"
                fi

                echo "$user $ip $pass" >> "$LOG/clear.txt"
                hashPass=$(openssl passwd -6 "$pass")
                echo "$user $ip $hashPass" >> "$LOG/passwdHashes.txt"
        done < "$LOG/users.txt"

        # Making clear.txt pretty
        column -t "$LOG/clear.txt" | awk 'NR>1 && $2!=prev {print ""} {print; prev=$2}' > "$LOG/clear.tmp"
        mv "$LOG/clear.tmp" "$LOG/clear.txt"

        grep -v "^$adminUser " "$LOG/passwdHashes.txt" > "$LOG/userHashes.txt"
        grep "^$adminUser " "$LOG/passwdHashes.txt" > "$LOG/adminHashes.txt"

# ----- confirmRoll() -----
        printf -- "\n----- New Passwords -----\n"
        cat "$LOG/clear.txt"
        printf "\nExecute? [y/N] "
        read -r confirm
        case $confirm in
                y) ;;
                *) return ;;
        esac

        printf -- "----- Admin Roll -----\n"
        while read -r user ip hash <&3; do
                oldPass="$(awk -v u="$user" -v i="$ip" '$1==u && $2==i {print $3}' "$LOG/adminUser.txt")"
                # This is likely unnecessary for the poor other person, but some versions of openssl add newlines in the hash, so base64 encoding is used so it doesn't freak out between shells (Dont ask how I know... :( )
                hash_b64=$(printf '%s' "$hash" | base64 -w 0)

                printf "Editing %-12s %-15s " "$user" "$ip"
                if "$DEPS/sshpass" -p "$oldPass" ssh -tt -o StrictHostKeyChecking=no "${user}@${ip}" "echo '$oldPass' | sudo -S -p '' usermod -p \"\$(printf '%s' $hash_b64 | base64 -d)\" $user 2>/dev/null" 2>/dev/null; then
                        echo OK
                        # Moved the admin update here since the admin password is needed for the user roll, and this way if the admin roll fails, the user roll won't execute with a broken password list
                        newPass="$(awk -v u="$user" -v i="$ip" '$1==u && $2==i {print $3}' "$LOG/clear.txt")"
                        awk -v u="$user" -v i="$ip" -v p="$newPass" \
                            '$1==u && $2==i {$3=p} {print}' \
                            "$LOG/adminUser.txt" > "$LOG/adminUser.tmp"
                        mv "$LOG/adminUser.tmp" "$LOG/adminUser.txt"
                else
                        echo FAIL
                fi
        done 3< "$LOG/adminHashes.txt"

        printf -- "----- User roll -----\n"
        while read -r user ip hash <&3; do
                adminUser="$(awk '{print $1; exit}' "$LOG/adminUser.txt")"
                adminPass="$(awk -v i="$ip" '$2==i {print $3; exit}' "$LOG/adminUser.txt")"
                hash_b64=$(printf '%s' "$hash" | base64 -w 0)

                printf "Editing %-12s %-15s " "$user" "$ip"
                if "$DEPS/sshpass" -p "$adminPass" ssh -tt -o StrictHostKeyChecking=no "${adminUser}@${ip}" "echo '$adminPass' | sudo -S -p '' usermod -p \"\$(printf '%s' $hash_b64 | base64 -d)\" $user 2>/dev/null" 2>/dev/null; then
                        echo OK
                else
                        echo FAIL
                fi
        done 3< "$LOG/userHashes.txt"

        # For PCR
        printf "\n----- New Admin Passwords -----\n"
        column -t "$LOG/adminUser.txt"
        printf "\n"
}

rollPasswd
