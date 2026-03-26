#!/bin/bash
psql -c "ALTER USER planka PASSWORD 'ChangeMe123!';"

cd /var/www/planka
curl -fsSL -O https://github.com/plankanban/planka/releases/latest/download/planka-prebuild.zip
unzip planka-prebuild.zip -d /var/www/
rm planka-prebuild.zip

cd /var/www/planka
npm install
