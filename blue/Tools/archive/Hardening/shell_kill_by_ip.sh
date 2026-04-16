# From Andrey Nikitin: chatgpt script for killing shells from a specific IP
#!/bin/bash
# Replace <target_ip> with the specific IP address you want to target
target_ip="X.X.X.X"

# Find all user sessions associated with the target IP and terminate them
for session_info in $(w -h | grep "$target_ip" | awk '{print $1 ":" $2}')
do
    user=$(echo $session_info | cut -d: -f1)
    tty=$(echo $session_info | cut -d: -f2)
    
    echo "Terminating session for user '$user' on TTY '$tty' coming from IP '$target_ip'"
    pkill -9 -t $tty
done

echo "All sessions for IP $target_ip have been terminated."