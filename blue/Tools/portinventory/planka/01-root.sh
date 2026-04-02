#!/bin/bash

# PostgreSQL-related commands
apt-get update
apt-get install postgresql postgresql-contrib -y

# Planka-related commands
echo 'Creating user planka...'
adduser planka
apt install unzip build-essential python3-venv -y
mkdir -p /var/www/planka/
cp .env /var/www/planka/
chown -R planka:planka /var/www/planka/

# Node-related commands
apt-get install ca-certificates curl gnupg -y
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

NODE_MAJOR=22
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

apt-get update
apt-get install nodejs -y


