# Meow
* This is the distribution engine for our scripts, commands, and tooling. 
* `meow.sh` is the driver. Output logs and artifacts from the scripts are delivered to their corresponding module directory
    * To run custom scripts, write the script's relative path to `meow`.
* `woof.sh` will be populated with system patches as we find them in our environment
* `ips.txt` is purely for convenience purposes to store targets

# To Do
* Deprecate the following directories in favor of their equivalent modules: 
  * `baks` $\rightarrow$ `squirrel`
  * `linux_agent_log` $\rightarrow$ `elk`
  * `net_enum_log` $\rightarrow$ `nematode`
  * `nmap_log` $\rightarrow$ DEPRECATED
  * `passwd_roll_log` $\rightarrow$ `flamingo`
  * `woof_log` $\rightarrow$ `woof`