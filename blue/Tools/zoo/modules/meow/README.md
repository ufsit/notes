# Meow
* This is the distribution engine for our scripts, commands, and tooling. 
* `meow.sh` is the driver. Output logs and artifacts from the scripts are delivered to their corresponding module directory
    * To run custom scripts, write the script's relative path to `meow.sh`.
* The module that transfers and/or executes a module on a target

# To Do:
* Establish ssh-keys instead of using sshpass
* Extend functionality to connect to Windows (WinRM, PSExec, SSH)