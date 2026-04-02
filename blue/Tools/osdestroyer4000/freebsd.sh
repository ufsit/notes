#!/bin/sh
touch /tmp/tlskeys
chmod 666 /tmp/tlskeys
echo 'export SSLKEYLOGFILE=/tmp/tlskeys' >> /etc/profile
