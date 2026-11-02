#!/bin/sh
# meerkat payload: generic service health (runs on target).
printf "===== FAILED SYSTEMD UNITS =====\n"
if failed_units=$(systemctl --failed --no-legend 2>/dev/null); then
    printf '%s\n' "$failed_units"
    failed_count=$(printf '%s\n' "$failed_units" | awk 'NF { count++ } END { print count + 0 }')
    if [ "$failed_count" -eq 0 ]; then
        failed_status="PASS ($failed_count)"
    elif [ "$failed_count" -eq 1 ]; then
        failed_status="WARN ($failed_count)"
    else
        failed_status="FAIL ($failed_count)"
    fi
else
    echo "(systemd unavailable)"
    failed_status="WARN (systemd unavailable)"
fi
printf "\n===== RUNNING SERVICES =====\n"
systemctl list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}'
printf "\n===== LISTENING SOCKETS =====\n"
ss -lntup 2>/dev/null || netstat -lntup 2>/dev/null
printf "\n===== UPTIME / LOAD =====\n"
uptime
printf "\n===== DISK USAGE =====\n"
if disk_usage=$(df -hP 2>/dev/null); then
    printf '%s\n' "$disk_usage" | awk 'NR == 1 || $0 !~ /tmpfs|devtmpfs|devfs|loop|overlay|^map /'
    disk_status=$(printf '%s\n' "$disk_usage" | awk '
        NR > 1 && $0 !~ /tmpfs|devtmpfs|devfs|loop|overlay|^map / {
            usage = $5
            sub(/%$/, "", usage)
            if (usage ~ /^[0-9]+$/) {
                checked++
                if (usage > max) {
                    max = usage
                    mount = $6
                }
            }
        }
        END {
            if (checked == 0) {
                print "WARN (no filesystems checked)"
            } else if (max >= 90) {
                printf "FAIL (%s at %d%%)", mount, max
            } else if (max >= 80) {
                printf "WARN (%s at %d%%)", mount, max
            } else {
                printf "PASS (max %d%%)", max
            }
        }')
else
    disk_status="WARN (disk usage unavailable)"
fi
printf "\n===== HEALTH STATUS =====\n"
printf 'Failed systemd units: %s\n' "$failed_status"
printf 'Disk usage: %s\n' "$disk_status"

overall_status="PASS"

case "$failed_status" in
    FAIL*) overall_status="FAIL" ;;
    WARN*) overall_status="WARN" ;;
esac

case "$disk_status" in
    FAIL*) overall_status="FAIL" ;;
    WARN*)
        if [ "$overall_status" = "PASS" ]; then
            overall_status="WARN"
        fi
        ;;
esac

printf 'Overall status: %s\n' "$overall_status"
