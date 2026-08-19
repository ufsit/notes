#!/bin/bash
# Elk: deploy the Elastic beats agent to every host (transfers via meow's $DEPS).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../meow/meow.sh"
meow_require_hosts || exit 1
log="$HERE/linux_agent_log/linux_agent_$(date +%H-%M-%S).out"; mkdir -p "$(dirname "$log")"; : > "$log"
printf "Elastic Server ip: "; read -r elastic_ip
printf "Kibana Server ip: ";  read -r kibana_ip
printf "CA Fingerprint: ";    read -r finger
printf "Elastic Password: ";  read -r elastic_pass
# heredoc feeds the installer's prompts, so this keeps its own ssh (meow_deploy uses ssh -n).
while read -r adminUser ip adminPass <&3; do
        [ -z "$ip" ] && continue
        printf -- "[----- ELK AGENT: %s; %s -----]\n" "$ip" "$(date +%H-%M-%S)" | tee -a "$log"
        "$DEPS/sshpass" -p "$adminPass" scp -o StrictHostKeyChecking=no \
                "$HERE/linux_agent.sh" "$HERE/alpine-beats.tar.gz" "$HERE/rules.conf" "$HERE/archive_install.sh" \
                "${adminUser}@${ip}:" >>"$log" 2>&1
        "$DEPS/sshpass" -p "$adminPass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 \
                "${adminUser}@${ip}" "sudo sh ~/linux_agent.sh" >>"$log" 2>&1 <<AGENT
$elastic_ip
$kibana_ip
$finger
$elastic_pass
AGENT
done 3< "$(meow_hosts)"
printf "\nSaved: %s\n" "$log"
