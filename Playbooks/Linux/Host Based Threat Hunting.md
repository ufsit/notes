## Host Based Threat hunting

Acquire, Preserve, & Document Evidence:
Capture the state of the system before any alterations can be made.
Do not reset any systems, may allow for attacks/evidence to disguise/delete.

**1. Check Host Health:**
Real time view of running processes


Commands to use: $ top, $ htop, $ mpstat, $ sar
-top = view of running processes
-htop = user friendly view of top
-mpstat = display reports of a processor's statistics
-sar = system activities
-sar -u = CPU utilization
-sar -r = Memory usage
-sar -b = I/O and transfer rates
-sar -n DEV = network statistics for devices
-sar -a = all available statistics

IOC's: 
- Spikes in CPU/Memory usage
- Unexpected/Unauthorized process/service activity
- FIM (File Integrity Monitoring) alerts
- Unexpected changes to files/directories, i.e. permissions, hidden
- User activity, i.e. logins, privileges, account changes



**2. Memory Dump:**
Capture RAM, artifacts, & other IOC that may be deleted

IOC’s:
- Hidden/Obfuscated processes
- Connection to unknown/malicious IP addresses/domains
- Evidence of malicious artifacts
- Modifications to kernel/process functions
- Modification/Creation of accounts with elevated privileges
- Processes/Commands with elevated privileges
- Process code injections


**3. Network Connections:**
Inspect active connections/sockets:

Commands to use: $ ss, $ netstat
-t = TCP sockets
-u = UDP sockets
-n = numerical address/port #
-a = All sockets
-p = PID / process owner

IOC's:

- Connection to suspicious infrastructure, i.e. C2 (command and control) servers, malicious IP's, or malicious domains 
- High volumes of outbound traffic
- Unexpected open/listening ports
- Suspicious DNS queries
- Recent network scanning
- Firewall rule changes

**4. Process Activity**
Identify process usages and their paths

Commands to use: $ top, $ htop, $ pstree, $ ps
-top = view of running processes
-htop = user friendly view of top
-pstree = tree structure of processes, visualization of relationships/usage
-ps -a = display all processes
-ps -u = user friendly format
-ps -x = processes not attached to control 

IOC's:
- Abnormal behavior, i.e. excessive resource usage, I/O activity, elevate privileges, modify user accounts, accessing sensitive files
- Unknown process discovery
- Evidence of malicious process artifacts
 
 **5. Open Files**
Discover open/active files

Commands to use: $ lsof, $ netstat
-lsof -p PID = inspect files opened by a specific process
-lsof -u username = list files opened by a specific user
-lsof -c command = list files opened by a command
-lsof -i = list network connections (TCP/UDP)

IOC's:
- Activity with sensitive files, i.e. exfiltration, ransomware, injection
- Packet sniffing processes
- Unusual file/script usage
- Hidden/Alterations to a file
- Excessive read volume, i.e. exfiltration
 


