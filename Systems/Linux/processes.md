# Table of Contents

- [Table of Contents](#table-of-contents)
- [Hijacking processes](#hijacking-processes)
  - [Path hijcaking](#path-hijcaking)
  - [Shared libraries](#shared-libraries)
  - [Symbolic linking](#symbolic-linking)
- [Monitoring processes](#monitoring-processes)
  - [ps](#ps)
    - [Example](#example)

# Hijacking processes

## Path hijcaking

When you run a command like `ls`, the system checks your path from left to right to see if the file exists. If an attacker can place a directory they can write to at the start of your path, then they can put malicious executables there, which take priority over `/bin`.

## Shared libraries

This is similar to Path hijacking for dynamically linked libraries. I don't understand it well so you can read more [here](https://tbhaxor.com/understanding-concept-of-shared-libraries/). It has something to do with `LD_PRELOAD` environmental variable.

## Symbolic linking

If a priviledged program creates a file `filename` in a directory writable by the user, the user can create a symlink `filename` that points to whatever file they want. This gives them write access to their target fille! You can see examples [here](https://lettieri.iet.unipi.it/hacking/ch/5-symlink.pdf).


# Monitoring processes
## ps
* `ps` - process inspection
  * `-e|-A` - shows all processes, identical flags
  * `-o [OPTIONS]` - user-defined format, accepted options in `STANDARD FORMAT SPECIFIERS` in man
    * euser - effective text user name
    * pid - pid
    * cmd - command and its arguments
  * `-u [USER_NAME]` - show effective user name of the next argument
    * `-x` - if we write x, i.e. `-ux`, since there are no `x` users, command will print every user's processes
  * `--forest` - ASCII art process tree
  * `-f` - Full-format listing, shows tree
  * `-H` - show process hierarchy
  * `-w` - wide output
### Example
* `ps aux`
* `ps auxf`
* `ps -eo euser,pid,cmd --forest | less`
* `ps -efwH`

