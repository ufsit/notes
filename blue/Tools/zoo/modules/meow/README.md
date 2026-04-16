# Meow
* This is the distribution engine for our scripts, commands, and tooling. 
* `meow.sh` is the driver. Output logs and artifacts from the scripts are delivered to their corresponding module directory
    * To run custom scripts, write the script's relative path to `meow.sh`.
* The module that transfers and/or executes a module on a target

# To Do
* Deprecate the following directories in favor of their equivalent modules: 
  * `baks` $\rightarrow$ `chipmunk`
  * `linux_agent_log` $\rightarrow$ `elk`
  * `net_enum_log` $\rightarrow$ `nematode`
  * `nmap_log` $\rightarrow$ `hawk`
  * `passwd_roll_log` $\rightarrow$ `elephant`
  * `woof_log` $\rightarrow$ `woof`
  * `cmd_log` & `script_log` $\rightarrow$ DEPRECATED
* Establish ssh-keys instead of using sshpass
* Extend functionality to connect to Windows (WinRM, PSExec, SSH)