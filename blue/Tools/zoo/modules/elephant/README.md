# Elephant
> Elephants have an incredibly good memory, and their job in this zoo is to remember and manage our passwords.

* This directory will contain the logic and management of user passwords across our hosts.
* Features:
  * Parse `/etc/passwd` and `/etc/shadow` into secure versions for every UNIX host
  * Execute a password change for local Windows users.
  * A password change request is able to target every users' password or a selection of users.