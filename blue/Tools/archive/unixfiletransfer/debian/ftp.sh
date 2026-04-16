mkdir /tmp/ftpsrv
../external/busybox/busybox tcpsvd -vE 0.0.0.0 21 ../external/busybox/busybox ftpd -wA /tmp/ftpsrv
