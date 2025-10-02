# Network Analysis
## netstat
* `--tcp|-t` - show tcp traffic
* `--udp|-u` - show udp traffic
* `--numeric|-n` - without this flag, ports information will show the service on that port, this flag will show the port number
* `--listening|-l` - shows listening sockets
* `--program|-p` - shows PID of the process and the process name, only with sudo
* `--all|-a` - shows listening and non-listening sockets
* `--continuous|-c` - shows the selected netstat information continuously
### Example
* All together: `netstat -tunlp`

## ss
* similar flags to netstat, a bit newer and faster, not as detailed as netstat but more concise (for our purposes, their interchangeable)
* netstat is more compatible and widely available