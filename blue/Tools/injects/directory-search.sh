#!/bin/bash

# Output file
output_file="data_directories.txt"

# Clear the output file if it exists
> "$output_file"

# Array of directories to check
directories=(
    "/var/lib/mysql"
    "/var/lib/postgresql"
	"/var/lib/pgsql"
	"/var/lib/mongodb"
    "/opt/epic"
    "/opt/cerner"
    "/srv/www"
    "/var/log/apache2"
    "/var/log/nginx"
	"/var/log/mysql"
	"/var/log/postgresql"
	"/var/log/pgsql"
    "/var/log/mongodb"
    "/tmp"
    "/var/tmp"
    "/backup"
    "/var/backups"
    "/var/www"
    "/usr/share/nginx"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "$dir" >> "$output_file"
    fi
done

echo "done"