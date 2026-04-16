#!/bin/tcsh
touch /tmp/tlskeys
chmod 666 /tmp/tlskeys
echo 'setenv SSLKEYLOGFILE /tmp/tlskeys' >> /etc/csh.cshrc
