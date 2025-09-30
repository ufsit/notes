# Table of Contents

- [Hijackcing processes](#hijacking-processes)
   - [Path hijacking](#path-hijcaking)
   - [Shared libraries](#shared-libraries)
   - [Symbolic linking](#symbolic-linking)
- [Monitoring processes](#monitoring-processes)

# Hijacking processes

## Path hijcaking

When you run a command like `ls`, the system checks your path from left to right to see if the file exists. If an attacker can place a directory they can write to at the start of your path, then they can put malicious executables there, which take priority over `/bin`.

## Shared libraries

This is similar to Path hijacking for dynamically linked libraries. I don't understand it well so you can read more [here](https://tbhaxor.com/understanding-concept-of-shared-libraries/). It has something to do with `LD_PRELOAD` environmental variable.

## Symbolic linking

If a priviledged program creates a file `filename` in a directory writable by the user, the user can create a symlink `filename` that points to whatever file they want. This gives them write access to their target fille! You can see examples [here](https://lettieri.iet.unipi.it/hacking/ch/5-symlink.pdf).


# Monitoring processes