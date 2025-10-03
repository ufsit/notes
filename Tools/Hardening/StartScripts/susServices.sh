## Has 2 modes:
## Full Output - Prints every service's execution commands to the screen. This is very noisy, but it doesn't filter out any sneaky services
## Filtered Output - Much smaller output that targets known binaries or patterns (ncat/netcat, bash, <ip> <port>, -p <port>) but may filter out sneaky backdoors
##
## Usage: `./susServices.sh filter` for filtered output and `./susServices.sh full` for full output

err_messg () {
  echo "Incorrect Usage"
  echo
  echo "Expected: "
  echo "  $0 filter"
  echo "  or"
  echo "  $0 full"
}

if [ $# -ne 1 ]; then
  err_messg
  exit 1
fi

if [ "$1" != "filter" ] &&  [ "$1" != "full" ]; then
  err_messg
  exit 1
fi

if [ "$1" = "full" ]; then
  echo "Printing all Exec commands for systemd services"
  echo
  grep -R "^Exec" /etc/systemd 2>/dev/null
fi

if [ "$1" = "filter" ]; then
  echo "Printing filtered Exec commands for systemd services"
  filterString="^Exec.*((\/tmp)|(\/bash)|(\/nc)|(\/netcat)|(\/ncat)|(-[lvn](?p|P)[lvn]? [1-9][0-9]{0,4})|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} [1-9][0-9]{0,4}))"
  echo
  grep -ER "$filterString" /etc/systemd 2>/dev/null
fi
