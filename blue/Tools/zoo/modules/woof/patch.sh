#!/bin/sh
# woof payload: detect common system/service misconfigurations (report-first).
printf "===== SSHD CONFIG =====\n"
c=/etc/ssh/sshd_config
if [ -r "$c" ]; then
  grep -Ei '^[[:space:]]*PermitRootLogin' "$c" || echo "PermitRootLogin: (default)"
  grep -Ei '^[[:space:]]*PasswordAuthentication' "$c" || echo "PasswordAuthentication: (default)"
  grep -Ei '^[[:space:]]*Port' "$c" || echo "Port: (default 22)"
else
  echo "(sshd_config not readable)"
fi
printf "\n===== WORLD-WRITABLE FILES IN /etc =====\n"
find /etc -xdev -type f -perm -0002 2>/dev/null | head -20 || printf "None found."

printf "\n===== EMPTY-PASSWORD ACCOUNTS =====\n"
awk -F: '($2==""){print $1}' /etc/shadow 2>/dev/null || echo "(shadow not readable)"
printf "\n===== .rhosts / hosts.equiv =====\n"
ls -la /etc/hosts.equiv 2>/dev/null; find /home -name .rhosts 2>/dev/null; echo "(scan complete)"


remidiate_world_writtable() {
    printf "Modifying file permissions for world writtable files in /etc/...\n"
    find /etc -xdev -type f -perm -0002 2>/dev/null |
	while IFS= read -r file; do
	    printf "\nWorld writtable file: $file\n"
	    stat --printf " user:%U\n group:%G\n perms:%a (%A)\n" "$file"
	    printf "\tModify permisions? (Y/N): "
	    read response < /dev/tty
	    while true; do
		case "$response" in
		    y|Y)
			printf "\tCHOICES:\n"
			printf "\t1. Remove world writable permission\n"
			printf "\t2. Change permissions to 644 (rw-r--r--)\n"
			printf "\t3. Change permissions to 640 (rw-r-----)\n"
			printf "\tOr enter octal digits: "
			read new_permissions < /dev/tty
			while true; do
			    case "$new_permissions" in
				1)
				    new_permissions="o-w"
				    break
				    ;;
				2)
				    new_permissions="644"
				    break
				    ;;
				3)
				    new_permissions="640"
				    break
				    ;;
				# custom permissions case
				[0-7][0-7][0-7]|[0-7][0-7][0-7][0-7])
				    break
				    ;;
				*)
				    printf "\tInvalid input, enter a number or octal code: "
				    read new_permissions < /dev/tty
				    ;;
			    esac
			done
			if chmod "$new_permissions" "$file"; then
			    stat --printf " Changed $file to %A permissions\n" "$file"
			else
			    printf "Failed to change permissions for $file\n"
			fi			
			break
			;;
		    n|N)
			break
			;;
		    *)
			printf  "\tInvalid input, choose Y or N: : "
			read response < /dev/tty
			;;	
		esac
	    done
	done
}


printf "\n\n===== WOOF WOOF WOOF =====\n\n"
printf "Completed audit report.\n\n"
printf "NOTICE: NEED ROOT PRIVILEGES TO MODIFY CONFIGURATION FILES!\n"
printf "Woof can be used to interactively:\n"
printf "1. Modify file permissions for world writtable files in /etc/\n\n"
printf "Enter a valid number, or anything else to quit: "
read response 
case "$response" in
    1)
	remidiate_world_writtable
	;;
    *)
	;;
esac
