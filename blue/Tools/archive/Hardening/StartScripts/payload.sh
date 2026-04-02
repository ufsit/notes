if ([ -f /usr/bin/id ] && [ "$(/usr/bin/id -u)" -eq "0" ]) || [ "`whoami 2>/dev/null`" = "root" ]; then
  IAMROOT="1"
  MAXPATH_FIND_W="3"
else
  IAMROOT=""
  MAXPATH_FIND_W="7"
fi



C=$(printf '\033')
RED="${C}[1;31m"
SED_RED="${C}[1;31m&${C}[0m"
GREEN="${C}[1;32m"
SED_GREEN="${C}[1;32m&${C}[0m"
YELLOW="${C}[1;33m"
SED_YELLOW="${C}[1;33m&${C}[0m"
RED_YELLOW="${C}[1;31;103m"
SED_RED_YELLOW="${C}[1;31;103m&${C}[0m"
BLUE="${C}[1;34m"
SED_BLUE="${C}[1;34m&${C}[0m"
ITALIC_BLUE="${C}[1;34m${C}[3m"
LIGHT_MAGENTA="${C}[1;95m"
SED_LIGHT_MAGENTA="${C}[1;95m&${C}[0m"
LIGHT_CYAN="${C}[1;96m"
SED_LIGHT_CYAN="${C}[1;96m&${C}[0m"
LG="${C}[1;37m" #LightGray
SED_LG="${C}[1;37m&${C}[0m"
DG="${C}[1;90m" #DarkGray
SED_DG="${C}[1;90m&${C}[0m"
NC="${C}[0m"
UNDERLINED="${C}[5m"
ITALIC="${C}[3m"


# Default Binaries List
sidG1="/abuild-sudo$|/accton$|/allocate$|/ARDAgent$|/arping$|/atq$|/atrm$|/authpf$|/authpf-noip$|/authopen$|/batch$|/bbsuid$|/bsd-write$|/btsockstat$|/bwrap$|/cacaocsc$|/camel-lock-helper-1.2$|/ccreds_validate$|/cdrw$|/chage$|/check-foreground-console$|/chrome-sandbox$|/chsh$|/cons.saver$|/crontab$|/ct$|/cu$|/dbus-daemon-launch-helper$|/deallocate$|/desktop-create-kmenu$|/dma$|/dma-mbox-create$|/dmcrypt-get-device$|/doas$|/dotlockfile$|/dotlock.mailutils$|/dtaction$|/dtfile$|/eject$|/execabrt-action-install-debuginfo-to-abrt-cache$|/execdbus-daemon-launch-helper$|/execdma-mbox-create$|/execlockspool$|/execlogin_chpass$|/execlogin_lchpass$|/execlogin_passwd$|/execssh-keysign$|/execulog-helper$|/exim4|/expiry$|/fdformat$|/fstat$|/fusermount$|/fusermount3$"
sidG2="/gnome-pty-helper$|/glines$|/gnibbles$|/gnobots2$|/gnome-suspend$|/gnometris$|/gnomine$|/gnotski$|/gnotravex$|/gpasswd$|/gpg$|/gpio$|/gtali|/.hal-mtab-lock$|/helper$|/imapd$|/inndstart$|/kismet_cap_nrf_51822$|/kismet_cap_nxp_kw41z$|/kismet_cap_ti_cc_2531$|/kismet_cap_ti_cc_2540$|/kismet_cap_ubertooth_one$|/kismet_capture$|/kismet_cap_linux_bluetooth$|/kismet_cap_linux_wifi$|/kismet_cap_nrf_mousejack$|/ksu$|/list_devices$|/load_osxfuse$|/locate$|/lock$|/lockdev$|/lockfile$|/login_activ$|/login_crypto$|/login_radius$|/login_skey$|/login_snk$|/login_token$|/login_yubikey$|/lpc$|/lpd$|/lpd-port$|/lppasswd$|/lpq$|/lpr$|/lprm$|/lpset$|/lxc-user-nic$|/mahjongg$|/mail-lock$|/mailq$|/mail-touchlock$|/mail-unlock$|/mksnap_ffs$|/mlocate$|/mlock$|/mount$|/mount.cifs$|/mount.ecryptfs_private$|/mount.nfs$|/mount.nfs4$|/mount_osxfuse$|/mtr$|/mutt_dotlock$"
sidG3="/ncsa_auth$|/netpr$|/netkit-rcp$|/netkit-rlogin$|/netkit-rsh$|/netreport$|/netstat$|/newgidmap$|/newtask$|/newuidmap$|/nvmmctl$|/opieinfo$|/opiepasswd$|/pam_auth$|/pam_extrausers_chkpwd$|/pam_timestamp_check$|/pamverifier$|/pfexec$|/ping$|/ping6$|/pmconfig$|/pmap$|/polkit-agent-helper-1$|/polkit-explicit-grant-helper$|/polkit-grant-helper$|/polkit-grant-helper-pam$|/polkit-read-auth-helper$|/polkit-resolve-exe-helper$|/polkit-revoke-helper$|/polkit-set-default-helper$|/postdrop$|/postqueue$|/poweroff$|/ppp$|/procmail$|/pstat$|/pt_chmod$|/pwdb_chkpwd$|/quota$|/rcmd|/remote.unknown$|/rlogin$|/rmformat$|/rnews$|/run-mailcap$|/sacadm$|/same-gnome$|screen.real$|/security_authtrampoline$|/sendmail.sendmail$|/shutdown$|/skeyaudit$|/skeyinfo$|/skeyinit$|/sliplogin|/slocate$|/smbmnt$|/smbumount$|/smpatch$|/smtpctl$|/sperl5.8.8$|/ssh-agent$|/ssh-keysign$|/staprun$|/startinnfeed$|/stclient$|/su$|/suexec$|/sys-suspend$|/sysstat$|/systat$"
sidG4="/telnetlogin$|/timedc$|/tip$|/top$|/traceroute6$|/traceroute6.iputils$|/trpt$|/tsoldtlabel$|/tsoljdslabel$|/tsolxagent$|/ufsdump$|/ufsrestore$|/ulog-helper$|/umount.cifs$|/umount.nfs$|/umount.nfs4$|/unix_chkpwd$|/uptime$|/userhelper$|/userisdnctl$|/usernetctl$|/utempter$|/utmp_update$|/uucico$|/uuglist$|/uuidd$|/uuname$|/uusched$|/uustat$|/uux$|/uuxqt$|/VBoxHeadless$|/VBoxNetAdpCtl$|/VBoxNetDHCP$|/VBoxNetNAT$|/VBoxSDL$|/VBoxVolInfo$|/VirtualBoxVM$|/vmstat$|/vmware-authd$|/vmware-user-suid-wrapper$|/vmware-vmx$|/vmware-vmx-debug$|/vmware-vmx-stats$|/vncserver-x11$|/volrmmount$|/w$|/wall$|/whodo$|/write$|/X$|/Xorg.wrap$|/Xsun$|/Xvnc$|/yppasswd$"

# Rules: Start path " /", end path "$", divide path and vulnversion "%". SPACE IS ONLY ALLOWED AT BEGINNING, DONT USE IT IN VULN DESCRIPTION
sidB="/apache2$%Read_root_passwd__apache2_-f_/etc/shadow\(CVE-2019-0211\)\
 /at$%RTru64_UNIX_4.0g\(CVE-2002-1614\)\
 /abrt-action-install-debuginfo-to-abrt-cache$%CENTOS 7.1/Fedora22
 /chfn$%SuSE_9.3/10\
 /chkey$%Solaris_2.5.1\
 /chkperm$%Solaris_7.0_\
 /chpass$%2Vulns:OpenBSD_6.1_to_OpenBSD 6.6\(CVE-2019-19726\)--OpenBSD_2.7_i386/OpenBSD_2.6_i386/OpenBSD_2.5_1999/08/06/OpenBSD_2.5_1998/05/28/FreeBSD_4.0-RELEASE/FreeBSD_3.5-RELEASE/FreeBSD_3.4-RELEASE/NetBSD_1.4.2\
 /chpasswd$%SquirrelMail\(2004-04\)\
 /dtappgather$%Solaris_7_<_11_\(SPARC/x86\)\(CVE-2017-3622\)\
 /dtprintinfo$%Solaris_10_\(x86\)_and_lower_versions_also_SunOS_5.7_to_5.10\
 /dtsession$%Oracle_Solaris_10_1/13_and_earlier\(CVE-2020-2696\)\
 /eject$%FreeBSD_mcweject_0.9/SGI_IRIX_6.2\
 /ibstat$%IBM_AIX_Version_6.1/7.1\(09-2013\)\
 /kcheckpass$%KDE_3.2.0_<-->_3.4.2_\(both_included\)\
 /kdesud$%KDE_1.1/1.1.1/1.1.2/1.2\
 /keybase-redirector%CentOS_Linux_release_7.4.1708\
 /login$%IBM_AIX_3.2.5/SGI_IRIX_6.4\
 /lpc$%S.u.S.E_Linux_5.2\
 /lpr$%BSD/OS2.1/FreeBSD2.1.5/NeXTstep4.x/IRIX6.4/SunOS4.1.3/4.1.4\(09-1996\)\
 /mail.local$%NetBSD_7.0-7.0.1__6.1-6.1.5__6.0-6.0.6
 /mount$%Apple_Mac_OSX\(Lion\)_Kernel_xnu-1699.32.7_except_xnu-1699.24.8\
 /movemail$%Emacs\(08-1986\)\
 /mrinfo$%NetBSD_Sep_17_2002_https://securitytracker.com/id/1005234\
 /mtrace$%NetBSD_Sep_17_2002_https://securitytracker.com/id/1005234\
 /netprint$%IRIX_5.3/6.2/6.3/6.4/6.5/6.5.11\
 /newgrp$%HP-UX_10.20\
 /ntfs-3g$%Debian9/8/7/Ubuntu/Gentoo/others/Ubuntu_Server_16.10_and_others\(02-2017\)\
 /passwd$%Apple_Mac_OSX\(03-2006\)/Solaris_8/9\(12-2004\)/SPARC_8/9/Sun_Solaris_2.3_to_2.5.1\(02-1997\)\
 /pkexec$%Linux4.10_to_5.1.17\(CVE-2019-13272\)/rhel_6\(CVE-2011-1485\)\
 /pppd$%Apple_Mac_OSX_10.4.8\(05-2007\)\
 /pt_chown$%GNU_glibc_2.1/2.1.1_-6\(08-1999\)\
 /pulseaudio$%\(Ubuntu_9.04/Slackware_12.2.0\)\
 /rcp$%RedHat_6.2\
 /rdist$%Solaris_10/OpenSolaris\
 /rsh$%Apple_Mac_OSX_10.9.5/10.10.5\(09-2015\)\
 /screen$%GNU_Screen_4.5.0\
 /sdtcm_convert$%Sun_Solaris_7.0\
 /sendmail$%Sendmail_8.10.1/Sendmail_8.11.x/Linux_Kernel_2.2.x_2.4.0-test1_\(SGI_ProPack_1.2/1.3\)\
 /snap-confine$%Ubuntu_snapd<2.37_dirty_sock_Local_Privilege_Escalation\(CVE-2019-7304\)\
 /sudo%check_if_the_sudo_version_is_vulnerable\
 /Serv-U%FTP_Server<15.1.7(CVE-2019-12181)
 /sudoedit$%Sudo/SudoEdit_1.6.9p21/1.7.2p4/\(RHEL_5/6/7/Ubuntu\)/Sudo<=1.8.14\
 /tmux$%Tmux_1.3_1.4_privesc\(CVE-2011-1496\)\
 /traceroute$%LBL_Traceroute_\[2000-11-15\]\
 /ubuntu-core-launcher$%Befre_1.0.27.1\(CVE-2016-1580\)\
 /umount$%BSD/Linux\(08-1996\)\
 /umount-loop$%Rocks_Clusters<=4.1\(07-2006\)\
 /uucp$%Taylor_UUCP_1.0.6\
 /XFree86$%XFree86_X11R6_3.3.x/4.0/4.x/3.3\(03-2003\)\
 /xlock$%BSD/OS_2.1/DG/UX_7.0/Debian_1.3/HP-UX_10.34/IBM_AIX_4.2/SGI_IRIX_6.4/Solaris_2.5.1\(04-1997\)\
 /xscreensaver%Solaris_11.x\(CVE-2019-3010\)\
 /xorg$%Xorg_1.19_to_1.20.x\(CVE_2018-14665\)/xorg-x11-server<=1.20.3/AIX_7.1_\(6.x_to_7.x_should_be_vulnerable\)_X11.base.rte<7.1.5.32_and_\
 /xterm$%Solaris_5.5.1_X11R6.3\(05-1997\)/Debian_xterm_version_222-1etch2\(01-2009\)"
# To update sidVB: curl https://github.com/GTFOBins/GTFOBins.github.io/tree/master/_gtfobins 2>/dev/null | grep 'href="/GTFOBins/' | grep '.md">' | awk -F 'title="' '{print $2}' | cut -d '"' -f1 | cut -d "." -f1 | sed  -e 's,^,/,' | sed  -e 's,$,\$,' | tr '\n' '|'
sidVB='/aa-exec$|/ab$|/agetty$|/alpine$|/ar$|/aria2c$|/arj$|/arp$|/as$|/ascii-xfr$|/ash$|/aspell$|/atobm$|/awk$|/base32$|/base64$|/basenc$|/basez$|/bash$|/batcat$|/bc$|/bridge$|/busctl$|/busybox$|/byebug$|/bzip2$|/cabal$|/capsh$|/cat$|/chmod$|/choom$|/chown$|/chroot$|/clamscan$|/cmp$|/column$|/comm$|/composer$|/cp$|/cpio$|/cpulimit$|/csh$|/csplit$|/csvtool$|/cupsfilter$|/curl$|/cut$|/dash$|/date$|/dc$|/dd$|/debugfs$|/dialog$|/diff$|/dig$|/distcc$|/dmsetup$|/docker$|/dosbox$|/dvips$|/ed$|/efax$|/elvish$|/emacs$|/env$|/eqn$|/espeak$|/expand$|/expect$|/file$|/find$|/fish$|/flock$|/fmt$|/fold$|/gawk$|/gcore$|/gdb$|/genie$|/genisoimage$|/gimp$|/ginsh$|/git$|/grep$|/gtester$|/gzip$|/hd$|/head$|/hexdump$|/highlight$|/hping3$|/iconv$|/iftop$|/install$|/ionice$|/ip$|/ispell$|/jjs$|/joe$|/join$|/jq$|/jrunscript$|/julia$|/ksh$|/ksshell$|/kubectl$|/latex$|/ldconfig$|/less$|/lftp$|/logsave$|/look$|/lua$|/lualatex$|/luatex$|/make$|/mawk$|/minicom$|/more$|/mosquitto$|/msgattrib$|/msgcat$|/msgconv$|/msgfilter$|/msgmerge$|/msguniq$|/multitime$|/mv$|/mysql$'
sidVB2='/nano$|/nasm$|/nawk$|/nc$|/ncdu$|/ncftp$|/nft$|/nice$|/nl$|/nm$|/nmap$|/node$|/nohup$|/ntpdate$|/octave$|/od$|/openssl$|/openvpn$|/pandoc$|/paste$|/pdflatex$|/pdftex$|/perf$|/perl$|/pexec$|/pg$|/php$|/pic$|/pico$|/pidstat$|/posh$|/pr$|/pry$|/psftp$|/ptx$|/python$|/rake$|/rc$|/readelf$|/restic$|/rev$|/rlwrap$|/rpm$|/rpmdb$|/rpmquery$|/rpmverify$|/rsync$|/rtorrent$|/run-parts$|/runscript$|/rview$|/rvim$|/sash$|/scanmem$|/scp$|/scrot$|/sed$|/setarch$|/setfacl$|/setlock$|/shuf$|/slsh$|/socat$|/soelim$|/softlimit$|/sort$|/sqlite3$|/ss$|/ssh-agent$|/ssh-keygen$|/ssh-keyscan$|/sshpass$|/start-stop-daemon$|/stdbuf$|/strace$|/strings$|/sysctl$|/systemctl$|/tac$|/tail$|/tar$|/taskset$|/tasksh$|/tbl$|/tclsh$|/tdbtool$|/tee$|/telnet$|/terraform$|/tex$|/tftp$|/tic$|/time$|/timeout$|/tmate$|/troff$|/ul$|/unexpand$|/uniq$|/unshare$|/unsquashfs$|/unzip$|/update-alternatives$|/uudecode$|/uuencode$|/vagrant$|/varnishncsa$|/view$|/vigr$|/vim$|/vimdiff$|/vipw$|/w3m$|/watch$|/wc$|/wget$|/whiptail$|/xargs$|/xdotool$|/xelatex$|/xetex$|/xmodmap$|/xmore$|/xxd$|/xz$|/yash$|/zip$|/zsh$|/zsoelim$'
cfuncs='file|free|main|more|read|split|write'

sudoVB1=" \*|env_keep\W*\+=.*LD_PRELOAD|env_keep\W*\+=.*LD_LIBRARY_PATH|7z$|aa-exec$|ab$|alpine$|ansible-playbook$|ansible-test$|aoss$|apache2ctl$|apt-get$|apt$|ar$|aria2c$|arj$|arp$|as$|ascii-xfr$|ascii85$|ash$|aspell$|at$|atobm$|awk$|aws$|base32$|base58$|base64$|basenc$|basez$|bash$|batcat$|bc$|bconsole$|bpftrace$|bridge$|bundle$|bundler$|busctl$|busybox$|byebug$|bzip2$|c89$|c99$|cabal$|capsh$|cat$|cdist$|certbot$|check_by_ssh$|check_cups$|check_log$|check_memory$|check_raid$|check_ssl_cert$|check_statusfile$|chmod$|choom$|chown$|chroot$|clamscan$|cmp$|cobc$|column$|comm$|composer$|cowsay$|cowthink$|cp$|cpan$|cpio$|cpulimit$|crash$|crontab$|csh$|csplit$|csvtool$|cupsfilter$|curl$|cut$|dash$|date$|dc$|dd$|debugfs$|dialog$|diff$|dig$|distcc$|dmesg$|dmidecode$|dmsetup$|dnf$|docker$|dosbox$|dotnet$|dpkg$|dstat$|dvips$|easy_install$|eb$|ed$|efax$|elvish$|emacs$|enscript$|env$|eqn$|espeak$|ex$|exiftool$|expand$|expect$|facter$|file$|find$|fish$|flock$|fmt$|fold$|fping$|ftp$|gawk$|gcc$|gcloud$|gcore$|gdb$|gem$|genie$|genisoimage$|ghc$|ghci$|gimp$|ginsh$|git$|grc$|grep$|gtester$|gzip$|hd$|head$|hexdump$|highlight$|hping3$|iconv$|iftop$|install$|ionice$|ip$|irb$|ispell$|jjs$|joe$|join$|journalctl$|jq$|jrunscript$|jtag$|julia$|knife$|ksh$|ksshell$|ksu$|kubectl$|latex$|latexmk$|ldconfig$|less$|lftp$|ln$|loginctl$|logsave$|look$|ltrace$|lua$|lualatex$|luatex$|lwp-download$|lwp-request$|mail$|make$|man$|mawk$|minicom$|more$|mosquitto$|mount$|msfconsole$|msgattrib$"
sudoVB2="msgcat$|msgconv$|msgfilter$|msgmerge$|msguniq$|mtr$|multitime$|mv$|mysql$|nano$|nasm$|nawk$|nc$|ncdu$|ncftp$|neofetch$|nft$|nice$|nl$|nm$|nmap$|node$|nohup$|npm$|nroff$|nsenter$|ntpdate$|octave$|od$|openssl$|openvpn$|openvt$|opkg$|pandoc$|paste$|pdb$|pdflatex$|pdftex$|perf$|perl$|perlbug$|pexec$|pg$|php$|pic$|pico$|pidstat$|pip$|pkexec$|pkg$|posh$|pr$|pry$|psftp$|psql$|ptx$|puppet$|pwsh$|python$|rake$|rc$|readelf$|red$|redcarpet$|restic$|rev$|rlwrap$|rpm$|rpmdb$|rpmquery$|rpmverify$|rsync$|ruby$|run-mailcap$|run-parts$|runscript$|rview$|rvim$|sash$|scanmem$|scp$|screen$|script$|scrot$|sed$|service$|setarch$|setfacl$|setlock$|sftp$|sg$|shuf$|slsh$|smbclient$|snap$|socat$|soelim$|softlimit$|sort$|split$|sqlite3$|sqlmap$|ss$|ssh-agent$|ssh-keygen$|ssh-keyscan$|ssh$|sshpass$|start-stop-daemon$|stdbuf$|strace$|strings$|su$|sudo$|sysctl$|systemctl$|systemd-resolve$|tac$|tail$|tar$|task$|taskset$|tasksh$|tbl$|tclsh$|tcpdump$|tdbtool$|tee$|telnet$|terraform$|tex$|tftp$|tic$|time$|timedatectl$|timeout$|tmate$|tmux$|top$|torify$|torsocks$|troff$|ul$|unexpand$|uniq$|unshare$|unsquashfs$|unzip$|update-alternatives$|uudecode$|uuencode$|vagrant$|valgrind$|varnishncsa$|vi$|view$|vigr$|vim$|vimdiff$|vipw$|virsh$|w3m$|wall$|watch$|wc$|wget$|whiptail$|wireshark$|wish$|xargs$|xdg-user-dir$|xdotool$|xelatex$|xetex$|xmodmap$|xmore$|xpad$|xxd$|xz$|yarn$|yash$|yum$|zathura$|zip$|zsh$|zsoelim$|zypper$"
sudoB="$(whoami)|ALL:ALL|ALL : ALL|ALL|env_keep|NOPASSWD|SETENV|/apache2|/cryptsetup|/mount"
sudoG="NOEXEC"

E=E
echo | sed -${E} 's/o/a/' 2>/dev/null
if [ $? -ne 0 ] ; then
  echo | sed -r 's/o/a/' 2>/dev/null
  if [ $? -eq 0 ] ; then
    E=r
  else
    echo "${YELLOW}WARNING: No suitable option found for extended regex with sed. Continuing but the results might be unreliable.${NC}"
  fi
fi

ROOT_FOLDER="/"
TIMEOUT="$(command -v timeout 2>/dev/null)"
STRACE="$(command -v strace_i_dont_want_strace 2>/dev/null)"
STRINGS="$(command -v strings 2>/dev/null)"
LDD="$(command -v ldd 2>/dev/null)"
READELF="$(command -v readelf 2>/dev/null)"

suids_files=$(find $ROOT_FOLDER -perm -4000 -type f ! -path "/dev/*" 2>/dev/null)
for s in $suids_files; do
  s=$(ls -lahtr "$s")
  # If starts like "total 332K" then no SUID bin was found and xargs just executed "ls" in the current folder
  if echo "$s" | grep -qE "^total"; then break; fi

  sname="$(echo $s | awk '{print $9}')"
  if [ "$sname" = "."  ] || [ "$sname" = ".."  ]; then
    true # Don't do nothing
  elif ! [ "$IAMROOT" ] && [ -O "$sname" ]; then
    echo "You own the SUID file: $sname" | sed -${E} "s,.*,${SED_RED},"
  elif ! [ "$IAMROOT" ] && [ -w "$sname" ]; then # If write permision, win found (no check exploits)
    echo "You can write SUID file: $sname" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  else
    c="a"
    for b in $sidB; do
      if echo $s | grep -q $(echo $b | cut -d % -f 1); then
        echo "$s" | sed -${E} "s,$(echo $b | cut -d % -f 1),${C}[1;31m&  --->  $(echo $b | cut -d % -f 2)${C}[0m,"
        c=""
        break;
      fi
    done;
    if [ "$c" ]; then
      if echo "$s" | grep -qE "$sidG1" || echo "$s" | grep -qE "$sidG2" || echo "$s" | grep -qE "$sidG3" || echo "$s" | grep -qE "$sidG4" || echo "$s" | grep -qE "$sidVB" || echo "$s" | grep -qE "$sidVB2"; then
        echo "$s" | sed -${E} "s,$sidG1,${SED_GREEN}," | sed -${E} "s,$sidG2,${SED_GREEN}," | sed -${E} "s,$sidG3,${SED_GREEN}," | sed -${E} "s,$sidG4,${SED_GREEN}," | sed -${E} "s,$sidVB,${SED_RED_YELLOW}," | sed -${E} "s,$sidVB2,${SED_RED_YELLOW},"
      else
        echo "$s (Unknown SUID binary!)" | sed -${E} "s,/.*,${SED_RED},"
        printf $ITALIC
        if ! [ "$FAST" ]; then
          
          if [ "$STRINGS" ]; then
            $STRINGS "$sname" 2>/dev/null | sort | uniq | while read sline; do
              sline_first="$(echo "$sline" | cut -d ' ' -f1)"
              if echo "$sline_first" | grep -qEv "$cfuncs"; then
                if echo "$sline_first" | grep -q "/" && [ -f "$sline_first" ]; then # If a path
                  if [ -O "$sline_first" ] || [ -w "$sline_first" ]; then # And modifiable
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is using $RED$sline_first$NC$ITALIC and you can modify it (strings line: $sline) (https://tinyurl.com/suidpath)\n"
                  fi
                else #If not a path
                  if [ ${#sline_first} -gt 2 ] && command -v "$sline_first" 2>/dev/null | grep -q '/' && echo "$sline_first" | grep -Eqv "\.\."; then # Check if existing binary
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is executing $RED$sline_first$NC$ITALIC and you can impersonate it (strings line: $sline) (https://tinyurl.com/suidpath)\n"
                  fi
                fi
              fi
            done
          fi

          if [ "$LDD" ] || [ "$READELF" ]; then
            echo "$ITALIC  --- Checking for writable dependencies of $sname...$NC"
          fi
          if [ "$LDD" ]; then
            "$LDD" "$sname" | grep -E "$Wfolders" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi
          if [ "$READELF" ]; then
            "$READELF" -d "$sname" | grep PATH | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi        
        fi
      fi
    fi
  fi
done;
echo ""

sgids_files=$(find $ROOT_FOLDER -perm -2000 -type f ! -path "/dev/*" 2>/dev/null)
for s in $sgids_files; do
  s=$(ls -lahtr "$s")
  # If starts like "total 332K" then no SUID bin was found and xargs just executed "ls" in the current folder
  if echo "$s" | grep -qE "^total";then break; fi

  sname="$(echo $s | awk '{print $9}')"
  if [ "$sname" = "."  ] || [ "$sname" = ".."  ]; then
    true #Don't do nothing
  elif ! [ "$IAMROOT" ] && [ -O "$sname" ]; then
    echo "You own the SGID file: $sname" | sed -${E} "s,.*,${SED_RED},"
  elif ! [ "$IAMROOT" ] && [ -w "$sname" ]; then # If write permision, win found (no check exploits)
    echo "You can write SGID file: $sname" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  else
    c="a"
    for b in $sidB; do
      if echo "$s" | grep -q $(echo $b | cut -d % -f 1); then
        echo "$s" | sed -${E} "s,$(echo $b | cut -d % -f 1),${C}[1;31m&  --->  $(echo $b | cut -d % -f 2)${C}[0m,"
        c=""
        break;
      fi
    done;
    if [ "$c" ]; then
      if echo "$s" | grep -qE "$sidG1" || echo "$s" | grep -qE "$sidG2" || echo "$s" | grep -qE "$sidG3" || echo "$s" | grep -qE "$sidG4" || echo "$s" | grep -qE "$sidVB" || echo "$s" | grep -qE "$sidVB2"; then
        echo "$s" | sed -${E} "s,$sidG1,${SED_GREEN}," | sed -${E} "s,$sidG2,${SED_GREEN}," | sed -${E} "s,$sidG3,${SED_GREEN}," | sed -${E} "s,$sidG4,${SED_GREEN}," | sed -${E} "s,$sidVB,${SED_RED_YELLOW}," | sed -${E} "s,$sidVB2,${SED_RED_YELLOW},"
      else
        echo "$s (Unknown SGID binary)" | sed -${E} "s,/.*,${SED_RED},"
        printf $ITALIC
        if ! [ "$FAST" ]; then
        
          if [ "$STRINGS" ]; then
            $STRINGS "$sname" | sort | uniq | while read sline; do
              sline_first="$(echo $sline | cut -d ' ' -f1)"
              if echo "$sline_first" | grep -qEv "$cfuncs"; then
                if echo "$sline_first" | grep -q "/" && [ -f "$sline_first" ]; then # If a path
                  if [ -O "$sline_first" ] || [ -w "$sline_first" ]; then # And modifiable
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is using $RED$sline_first$NC$ITALIC and you can modify it (strings line: $sline)\n"
                  fi
                else # If not a path
                  if [ ${#sline_first} -gt 2 ] && command -v "$sline_first" 2>/dev/null | grep -q '/'; then # Check if existing binary
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is executing $RED$sline_first$NC$ITALIC and you can impersonate it (strings line: $sline)\n"
                  fi
                fi
              fi
            done
          fi

          if [ "$LDD" ] || [ "$READELF" ]; then
            echo "$ITALIC  --- Checking for writable dependencies of $sname...$NC"
          fi
          if [ "$LDD" ]; then
            "$LDD" "$sname" | grep -E "$Wfolders" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi
          if [ "$READELF" ]; then
            "$READELF" -d "$sname" | grep PATH | grep -E "$Wfolders" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi        
        fi
      fi
    fi
  fi
done;
echo ""
