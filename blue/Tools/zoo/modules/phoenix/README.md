# Phoenix
* Automated firewall tasks

## Implementations Ideas
* Whitelists
* Use packet captures
* Use `ss` to determine a base of allowed ports, and then fine-tune them further
* Block all outbound traffic
    * Automated way to execute unlock the firewall for a command and restore to block all outbound traffic
* Red team has changed the SSH port in the past, Phoenix could attempt to fix this