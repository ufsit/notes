# Flamingo
> Flamingos are pink because of their heavy diet of shrimp. Like flamingos, our users change color based on their favorite meal: passwords.

* This directory will contain the logic and management of user passwords across our hosts.
* Features:
  * Parse `/etc/passwd` and `/etc/shadow` into secure versions for every UNIX host
  * Execute a password change for local Windows users.
  * A password change request may involve rolling every password, or a selection of users.