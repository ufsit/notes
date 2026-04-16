#!/bin/bash
touch /opt/tlskeys
chmod 666 /opt/tlskeys
echo 'export SSLKEYLOGFILE=/opt/tlskeys' >> /etc/profile
