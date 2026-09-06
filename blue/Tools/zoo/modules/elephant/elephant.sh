#!/bin/bash
# Elephant: generation and management of user passwords across hosts.
# Sources meow's driver library for shared helpers ($DEPS, genPasswd, host list).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
. "$HERE/../hawk/hawk.sh"
LOG="$HERE/passwd_roll_log"
mkdir -p "$LOG"

initAdmin() {
        printf "If mistaken, Ctrl+c to exit
"
        printf "Admin:				"
        read -r adminUser
        printf "Password:			"
        read -r adminPass
        while :; do
                : > "$LOG/adminUser.txt"
                ips=""
                while :; do
                        printf "IP Address (x to stop):		"
                        read -r ip
                        case "$ip" in
                                x) break ;;
                                *) ips="$ips $ip" ;;
                        esac
                done

                printf "
Fingerprinting OS with hawk nmap...
"
                hawk_osmap $ips > "$LOG/osmap.tmp"
                while read -r ip os <&3; do
                        dom='-'
                        case "$os" in
                                windows)
                                        printf "  %-15s windows -- domain (blank = local admin): " "$ip"
                                        read -r dom; [ -z "$dom" ] && dom='-' ;;
                                unknown)
                                        printf "  %-15s unknown -- [l]inux / [w]indows / [s]kip: " "$ip"
                                        read -r ans
                                        case "$ans" in
                                                w) os=windows
                                                        printf "    domain (blank = local admin): "
                                                        read -r dom; [ -z "$dom" ] && dom='-' ;;
                                                s) continue ;;
                                                *) os=linux ;;
                                        esac ;;
                        esac
                        printf '%s %s %s %s %s
' "$adminUser" "$ip" "$adminPass" "$os" "$dom" >> "$LOG/adminUser.txt"
                done 3< "$LOG/osmap.tmp"
                rm -f "$LOG/osmap.tmp"

                printf "
----- adminUser.txt (USER IP PASSWORD OS DOMAIN) -----
"
                column -t "$LOG/adminUser.txt"
                printf '
Confirm? [y/N]: '
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


# Requires a host list built by the Setup Hosts step (initAdmin).
        if [ ! -s "$LOG/adminUser.txt" ]; then
                printf "No host list yet -- run 'Setup Hosts' first.\n" >&2
                return 1
        fi

# ----- genUserList() -----
        rm -f "$LOG/users.txt"
        while read -r adminUser ip adminPass os domain; do
                [ "$os" = windows ] && continue
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

        rollWindows
}

rollWindows() {
        wins="$(awk '$4=="windows"{print}' "$LOG/adminUser.txt")"
        [ -z "$wins" ] && return 0
        printf -- "\n===== Windows Roll =====\n"
        : > "$LOG/clear_win.txt"
        printf '%s\n' "$wins" | while read -r user ip pass os domain; do
                [ -z "$ip" ] && continue
                printf -- "----- %s (%s) -----\n" "$ip" "$domain"
                case "$domain" in ''|-|.) flag="-L" ;; *) flag="-D" ;; esac
                meow_win_put "$user" "$ip" "$pass" "$domain" "$HERE/roll_passwords.ps1" "\\Windows\\Temp\\roll_passwords.ps1"
                meow_win_put "$user" "$ip" "$pass" "$domain" "$HERE/words.txt"          "\\Windows\\Temp\\words.txt"
                out="$(meow_win_run "$user" "$ip" "$pass" "$domain" "powershell -ExecutionPolicy Bypass -Command \"Set-Location C:\\Windows\\Temp; .\\roll_passwords.ps1 $flag; Remove-Item -Force -ErrorAction SilentlyContinue roll_passwords.ps1,words.txt\"" 2>&1)"
                printf '%s\n' "$out" | grep -v 'ZOOCRED:'
                creds="$(printf '%s\n' "$out" | tr -d '\r' | sed -n 's/.*ZOOCRED://p' | while IFS= read -r b; do [ -n "$b" ] && { printf '%s' "$b" | base64 -d 2>/dev/null; printf '\n'; }; done)"
                if [ -n "$creds" ]; then
                        printf '%s\n' "$creds" >> "$LOG/clear_win.txt"
                        printf "  rolled %s account(s)\n" "$(printf '%s\n' "$creds" | grep -c .)"
                        newpass="$(printf '%s\n' "$creds" | awk -F: -v u="$user" '{ n=$1; sub(/.*\\/,"",n); if (tolower(n)==tolower(u)) { print $2; exit } }')"
                        if [ -n "$newpass" ]; then
                                awk -v ip="$ip" -v u="$user" -v np="$newpass" '$1==u && $2==ip {$3=np} {print}' "$LOG/adminUser.txt" > "$LOG/adminUser.tmp" && mv "$LOG/adminUser.tmp" "$LOG/adminUser.txt"
                                printf "  updated stored password for %s@%s\n" "$user" "$ip"
                        fi
                else
                        printf "  no creds returned from %s\n" "$ip"
                fi
        done
        chmod 600 "$LOG/clear_win.txt" 2>/dev/null
        printf -- "\nWindows creds (plaintext) saved -> %s\n\n" "$LOG/clear_win.txt"
}

case "$1" in
        init) initAdmin ;;
        *)    rollPasswd ;;
esac
