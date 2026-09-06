undo() {
  sleep $1
  case $2 in
    y) printf "\n\033[01m\033[33mBlackout over!\033[00m\n";;
    n) :;;
  pfctl -d
}
kldload pf
pfctl -d
for ip in $(netstat -an | grep 'ESTABLISHED' | grep 'tcp4' | grep '22' | awk '{print $5}' | cut -d'.' -f1-4 | sort -u)
  do echo "Allow $ip? [y|n]"
  read ans
  case $ans in
    y) 	pfctl -t imps -T add "$ip"
    n) :;;
  esac
done
pfctl -f rules
undo 3 n &
pfctl -e

echo "Say something if you are still connected:"
read connected

sleep 3

undo 60 y &
pfctl -e

echo "You have 1 minute to harden your system!"
