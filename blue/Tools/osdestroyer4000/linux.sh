#!/bin/bash
touch /opt/tlskeys
chmod 666 /opt/tlskeys
echo 'SSLKEYLOGFILE=/opt/tlskeys' >> /etc/environment
