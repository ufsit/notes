#!/usr/bin/env bash
set -euo pipefail

TIMEOUT_SECS=4
MAX_GREP_HITS=200
MAX_CONFIG_DUMP=900
MAX_PS=180
MAX_JOURNAL=160

# Depth controls (prevents terminal flooding)
DIR_DEPTH_ROOT=1          # show /var/www/<app>
DIR_DEPTH_APP=2           # show /var/www/<app>/<subdirs...> (up to N deep)
MAX_DIR_LINES=220         # cap dir listing lines per block
MAX_RECENT_FILES=40       # cap recent file list per root (optional, small)
MAX_KEY_FILES=60          # cap "key files" list per root (optional, small)

ts() { date +"%Y-%m-%d %H:%M:%S %Z"; }
hr() { printf '\n%s\n' "================================================================================"; }
h1() { hr; printf '%s\n' "$1"; hr; }
h2() { printf '\n--- %s ---\n' "$1"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

timeout_cmd() {
  if need_cmd timeout; then
    timeout "${TIMEOUT_SECS}" "$@"
  else
    "$@"
  fi
}

run() {
  local title="$1"; shift
  h2 "$title"
  ( set +e; timeout_cmd "$@" ) 2>&1 | sed 's/\r$//'
  return 0
}

# ------------ portability helpers ------------
has_find_printf() {
  # BSD find often supports -print, GNU find supports -printf. Probe.
  find / -maxdepth 0 -printf '' >/dev/null 2>&1
}

find_dirs() {
  # find_dirs BASE MINDEPTH MAXDEPTH
  local base="$1" mind="$2" maxd="$3"
  [ -d "$base" ] || return 0

  if has_find_printf; then
    find "$base" -xdev -mindepth "$mind" -maxdepth "$maxd" -type d -printf '%p\n' 2>/dev/null
  else
    find "$base" -xdev -mindepth "$mind" -maxdepth "$maxd" -type d 2>/dev/null
  fi
}

dir_tree_limited() {
  # dir_tree_limited BASE MAXDEPTH LABEL
  local base="$1" maxd="$2" label="${3:-$base}"
  [ -d "$base" ] || return 0

  h2 "Directory tree: $label (depth<=${maxd})"
  echo "base: $base"
  echo "perms: $(stat -c '%A %U:%G %n' "$base" 2>/dev/null || ls -ld "$base" 2>/dev/null || echo 'stat/ls failed')"

  # Print directories only, depth-limited
  find_dirs "$base" 1 "$maxd" | head -n "$MAX_DIR_LINES" || true
  local shown
  shown="$(find_dirs "$base" 1 "$maxd" | wc -l | tr -d ' ' 2>/dev/null || echo 0)"
  if [ "${shown:-0}" -gt "$MAX_DIR_LINES" ]; then
    echo "(capped; more dirs exist)"
  fi

  # Summaries (counts), depth-limited to avoid huge walks
  local dcount fcount
  dcount="$(find "$base" -xdev -mindepth 1 -maxdepth "$maxd" -type d 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  fcount="$(find "$base" -xdev -mindepth 1 -maxdepth "$maxd" -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  echo "counts(depth<=${maxd}): dirs=${dcount} files=${fcount}"
}

list_top_entries() {
  local base="$1" n="${2:-30}"
  [ -d "$base" ] || return 0
  h2 "Top entries: $base (ls -la | head -n ${n})"
  ls -la "$base" 2>/dev/null | head -n "$n" || true
}

recent_files_limited() {
  # Small, useful: show only a handful of recent file changes (not full file trees).
  local base="$1"
  [ -d "$base" ] || return 0
  h2 "Recent file changes in $base (mtime<24h; top ${MAX_RECENT_FILES})"
  find "$base" -xdev -type f -mtime -1 2>/dev/null \
    | head -n 800 \
    | while IFS= read -r f; do
        # Portable-ish stat
        if stat -c '%y %U:%G %n' "$f" >/dev/null 2>&1; then
          stat -c '%y %U:%G %n' "$f"
        else
          # BSD stat
          stat -f '%Sm %Su:%Sg %N' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo "$f"
        fi
      done \
    | sort -r \
    | head -n "$MAX_RECENT_FILES" || true
}

key_files_limited() {
  # Show "entrypoint-ish" file names, capped, without dumping everything.
  local base="$1"
  [ -d "$base" ] || return 0
  h2 "Key web/app files in $base (depth<=2; top ${MAX_KEY_FILES})"
  find "$base" -xdev -maxdepth 2 -type f 2>/dev/null \
    | grep -Ei '(/index\.(php|html?|jsp|aspx?)$|/wp-config\.php$|/config(\.inc)?\.php$|/\.env$|/composer\.json$|/package\.json$|/Dockerfile$|/docker-compose\.ya?ml$|/Caddyfile$|/nginx\.conf$|/httpd\.conf$|/apache2\.conf$|/web\.config$|/application\.ya?ml$|/settings\.py$|/manage\.py$)' \
    | head -n "$MAX_KEY_FILES" || true
}

important_app_dirs_under() {
  # Print base-level app directories (depth 1) that look "important".
  # Output: absolute paths.
  local base="$1"
  [ -d "$base" ] || return 0

  # Known high-signal names (case-insensitive)
  local name_pat='(phpmyadmin|pma|adminer|wordpress|wp|drupal|joomla|tikiwiki|twiki|mediawiki|jenkins|grafana|kibana|gitlab|gitea|redmine|nagios|zabbix|rundeck|confluence|jira|tomcat|manager|console|webmin|cockpit|prometheus|elastic|logstash|sonar|nexus|harbor)'

  find "$base" -xdev -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | grep -Ei "/[^/]*${name_pat}[^/]*$" || true

  # Heuristic: directories containing common entrypoints within depth 2
  find "$base" -xdev -mindepth 1 -maxdepth 2 -type f 2>/dev/null \
    | grep -Ei '/(index\.(php|html?|jsp|aspx?)|wp-config\.php|config(\.inc)?\.php|application\.ya?ml|settings\.py|manage\.py)$' \
    | awk -F/ -v b="$base" '
        $0 ~ "^"b"/" {
          # return the /base/<app> directory
          print b"/"$4
        }
      ' \
    | sort -u || true
}

# ---------------- header ----------------
h1 "WEB TRIAGE — $(hostname) — $(ts)"
echo "user: $(id -un) uid=$(id -u) groups=$(id -Gn)"
echo "kernel: $(uname -r)"
if [ -f /etc/os-release ]; then
  echo "os: $(. /etc/os-release; echo "${PRETTY_NAME:-$NAME $VERSION}")"
else
  echo "os: unknown"
fi
echo "cwd: $(pwd)"
echo "uptime: $(uptime -p 2>/dev/null || true)"

# --------------- 1) listeners + net ---------------
h1 "1) LISTENERS / NETWORK (what is exposed?)"
if need_cmd ss; then
  run "Listeners (ss -tulpen)" ss -tulpen
elif need_cmd netstat; then
  run "Listeners (netstat -tulpen)" netstat -tulpen
else
  echo "No ss/netstat available."
fi

# ip -br doesn't exist on older iproute2; use fallback
if need_cmd ip; then
  run "IPs / routes" bash -lc 'ip -br a 2>/dev/null || ip a; echo; ip r; echo; ip -br link 2>/dev/null || ip link'
elif need_cmd ifconfig; then
  run "Interfaces (ifconfig -a)" ifconfig -a
  if need_cmd route; then run "Routes (route -n)" route -n; fi
fi

if need_cmd nft; then
  run "Firewall (nft ruleset — first 200 lines)" bash -lc 'nft list ruleset 2>/dev/null | head -n 200'
fi
if need_cmd iptables; then
  run "Firewall (iptables filter)" iptables -S
  run "Firewall (iptables nat)" iptables -t nat -S
fi
if need_cmd ufw; then
  run "Firewall (ufw status verbose)" ufw status verbose
fi
if need_cmd firewall-cmd; then
  run "Firewall (firewalld state)" firewall-cmd --state
  run "Firewall (firewalld active zones)" firewall-cmd --get-active-zones
fi

# --------------- 2) services + processes ---------------
h1 "2) SERVICES / PROCESSES (what web stack exists?)"
if need_cmd systemctl; then
  run "Running services (top 200)" bash -lc 'systemctl --no-pager --type=service --state=running | head -n 200'
  run "Web-ish services (grep)" bash -lc 'systemctl --no-pager --type=service --all | grep -Ei "(nginx|apache2|httpd|caddy|lighttpd|traefik|haproxy|varnish|tomcat|jetty|gunicorn|uwsgi|php-fpm|node|pm2|docker|podman|redis|postgres|mysql|mariadb|mongodb|elasticsearch|kibana|grafana)" | head -n 250 || true'
elif need_cmd service; then
  run "service --status-all (filtered)" bash -lc 'service --status-all 2>/dev/null | grep -Ei "(nginx|apache|httpd|php|tomcat|mysql|postgres|redis|docker)" | head -n 250 || true'
fi

run "Web-ish processes (ps grep; top ${MAX_PS})" bash -lc \
  "ps auxwww | grep -Ei \"(nginx|apache2|httpd|caddy|lighttpd|traefik|haproxy|varnish|tomcat|jetty|gunicorn|uwsgi|php-fpm|node|pm2|rails|puma|unicorn|dotnet|kestrel|spring|flask|django)\" | grep -v grep | head -n ${MAX_PS} || true"

# --------------- 3) web server config visibility ---------------
h1 "3) WEB SERVER / PROXY CONFIGS (vhosts, proxies, docroots, modules)"

if need_cmd nginx; then
  run "nginx -v" nginx -v
  run "nginx -T (first ${MAX_CONFIG_DUMP} lines)" bash -lc "timeout_cmd nginx -T 2>&1 | sed -n '1,${MAX_CONFIG_DUMP}p'"
else
  [ -d /etc/nginx ] && run "/etc/nginx exists — list key dirs" bash -lc 'ls -la /etc/nginx; echo; ls -la /etc/nginx/sites-enabled 2>/dev/null || true; ls -la /etc/nginx/conf.d 2>/dev/null || true'
fi

if need_cmd apachectl; then
  run "apachectl -v" apachectl -v
  run "apachectl -S (vhosts)" apachectl -S
  run "apachectl -M (modules; first 200 lines)" bash -lc 'apachectl -M 2>&1 | head -n 200'
elif need_cmd httpd; then
  run "httpd -v" httpd -v
  run "httpd -S (vhosts)" httpd -S
fi

[ -d /etc/apache2 ] && run "/etc/apache2 sites-enabled + ports.conf" bash -lc 'ls -la /etc/apache2/sites-enabled 2>/dev/null || true; echo; sed -n "1,200p" /etc/apache2/ports.conf 2>/dev/null || true'
[ -d /etc/httpd ] && run "/etc/httpd conf.d listing" bash -lc 'ls -la /etc/httpd; echo; ls -la /etc/httpd/conf.d 2>/dev/null || true'

if need_cmd caddy; then
  run "caddy version" caddy version
  run "Caddyfile paths" bash -lc 'ls -la /etc/caddy 2>/dev/null || true; ls -la /etc/caddy/Caddyfile 2>/dev/null || true'
fi
if need_cmd lighttpd; then
  run "lighttpd -v" lighttpd -v
  run "lighttpd configs" bash -lc 'ls -la /etc/lighttpd 2>/dev/null || true; ls -la /etc/lighttpd/conf-enabled 2>/dev/null || true'
fi
if need_cmd haproxy; then
  run "haproxy version (short)" bash -lc 'haproxy -vv 2>/dev/null | head -n 60 || true'
  run "haproxy.cfg (first 220 lines)" bash -lc 'sed -n "1,220p" /etc/haproxy/haproxy.cfg 2>/dev/null || true'
fi
if need_cmd traefik; then
  run "traefik version" traefik version 2>/dev/null || true
  run "traefik config paths" bash -lc 'ls -la /etc/traefik 2>/dev/null || true; ls -la /etc/traefik/traefik.y*ml 2>/dev/null || true'
fi

if need_cmd php-fpm; then
  run "php-fpm -v" php-fpm -v
fi
[ -d /etc/php ] && run "/etc/php (php-fpm pools often here)" bash -lc 'find /etc/php -maxdepth 3 -type f -name "*.conf" 2>/dev/null | grep -Ei "(fpm|pool|php-fpm)" | head -n 150 || true'

# --------------- 4) docroot/app root discovery ---------------
h1 "4) DOCROOT / APP ROOT DISCOVERY (where content lives?)"

declare -a ROOTS=()
add_root() {
  local p="$1"
  [ -d "$p" ] || return 0
  for r in "${ROOTS[@]:-}"; do [ "$r" = "$p" ] && return 0; done
  ROOTS+=("$p")
}

add_root /var/www
add_root /var/www/html
add_root /srv/www
add_root /usr/share/nginx/html
add_root /usr/local/www
add_root /opt

if need_cmd nginx; then
  while IFS= read -r line; do
    p="$(printf '%s' "$line" | sed -nE 's/^[[:space:]]*root[[:space:]]+([^;]+);.*/\1/p')"
    [ -n "$p" ] && add_root "$p"
  done < <(timeout_cmd nginx -T 2>/dev/null | head -n 12000 || true)
fi

for f in /etc/apache2/sites-enabled/* /etc/apache2/sites-available/* /etc/httpd/conf.d/* /etc/httpd/conf/*; do
  [ -f "$f" ] || continue
  while IFS= read -r dr; do
    p="$(printf '%s' "$dr" | awk '{print $2}' | tr -d '"')"
    [ -n "$p" ] && add_root "$p"
  done < <(grep -RInhE '^[[:space:]]*DocumentRoot[[:space:]]+' "$f" 2>/dev/null || true)
done

if [ "${#ROOTS[@]}" -eq 0 ]; then
  echo "No obvious docroots found."
else
  echo "Candidate roots:"
  for r in "${ROOTS[@]}"; do echo "  - $r"; done
fi

# --------------- 5) surface inventory (directory-focused, not files) ---------------
h1 "5) SURFACE INVENTORY (directory view, not file spam)"

for r in "${ROOTS[@]}"; do
  [ -d "$r" ] || continue

  # Always show top-level structure only
  list_top_entries "$r" 35
  dir_tree_limited "$r" "$DIR_DEPTH_ROOT" "$r"

  # If /var/www (or similar), highlight "important" app dirs and show one extra level within each
  if [ "$r" = "/var/www" ] || [ "$r" = "/var/www/html" ] || [ "$r" = "/srv/www" ]; then
    h2 "Important-looking app directories under $r"
    mapfile -t IMP < <(important_app_dirs_under "$r" | sort -u)

    if [ "${#IMP[@]}" -eq 0 ]; then
      echo "(none detected by heuristic)"
    else
      printf '%s\n' "${IMP[@]}" | head -n 80
      echo

      for app in "${IMP[@]}"; do
        [ -d "$app" ] || continue
        dir_tree_limited "$app" "$DIR_DEPTH_APP" "$app"
        key_files_limited "$app"
        recent_files_limited "$app"
      done
    fi
  else
    # For non-/var/www docroots: show a shallow tree and a small key-file + recent-file view
    dir_tree_limited "$r" "$DIR_DEPTH_APP" "$r"
    key_files_limited "$r"
    recent_files_limited "$r"
  fi
done

# --------------- 6) config greps (high signal, capped) ---------------
h1 "6) CONFIG HOTSPOTS (reverse proxy, admin panels, autoindex, allow-all)"

CFG_PATHS=(/etc/nginx /etc/apache2 /etc/httpd /etc/caddy /etc/lighttpd /etc/haproxy /etc/traefik)

grep_cap() {
  local label="$1"; shift
  local pat="$1"; shift
  h2 "$label"
  echo "pattern: $pat"
  for p in "${CFG_PATHS[@]}"; do
    [ -e "$p" ] || continue
    echo "==> $p"
    grep -RInE --binary-files=without-match "$pat" "$p" 2>/dev/null | head -n "$MAX_GREP_HITS" || true
  done
}

grep_cap "Reverse proxy / upstreams" '(proxy_pass|ProxyPass|fastcgi_pass|uwsgi_pass|grpc_pass|upstream[[:space:]]+|balancer://|PassReverse)'
grep_cap "Admin/status/debug-ish endpoints" '(server-status|stub_status|phpinfo|/debug|/admin|/manage|/console|/actuator|/metrics|/prometheus|/swagger|/graphql|/jenkins|/grafana|/kibana|/phpmyadmin|/pma)'
grep_cap "Autoindex / directory listing enabled" '(autoindex[[:space:]]+on|Options[[:space:]]+.*Indexes)'
grep_cap "Allow-all / Require granted / satisfy any" '(allow[[:space:]]+all|Require[[:space:]]+all[[:space:]]+granted|satisfy[[:space:]]+any)'

# --------------- 7) sensitive file presence (names only, depth-limited) ---------------
h1 "7) SENSITIVE FILE PRESENCE (names only, capped)"

SENSITIVE_PAT='(\.env$|\.pem$|id_rsa|id_ed25519|\.bak$|\.old$|\.swp$|~$|backup|dump|\.sql$|\.sqlite$|\.db$|/\.git$|/\.git/|composer\.lock$|package-lock\.json$|yarn\.lock$|web\.config\.bak$)'

for r in "${ROOTS[@]}"; do
  [ -d "$r" ] || continue
  h2 "Sensitive-ish filenames in $r (depth<=3; top 120)"
  find "$r" -xdev -maxdepth 3 -type f 2>/dev/null \
    | grep -E "$SENSITIVE_PAT" \
    | head -n 120 || true
done

# --------------- 8) TLS/certs ---------------
h1 "8) TLS / CERTS (dirs + referenced cert expiry)"

if need_cmd openssl; then
  for d in /etc/letsencrypt /etc/ssl /usr/local/etc/ssl /var/lib/acme; do
    [ -d "$d" ] || continue
    h2 "Cert directory: $d (top 80 entries)"
    ls -la "$d" 2>/dev/null | head -n 80 || true
  done
fi

declare -a CERTS=()
add_cert() { local p="$1"; [ -f "$p" ] || return 0; for c in "${CERTS[@]:-}"; do [ "$c" = "$p" ] && return 0; done; CERTS+=("$p"); }

if need_cmd nginx; then
  while IFS= read -r line; do
    p="$(printf '%s' "$line" | sed -nE 's/^[[:space:]]*ssl_certificate[[:space:]]+([^;]+);.*/\1/p')"
    [ -n "$p" ] && add_cert "$p"
  done < <(timeout_cmd nginx -T 2>/dev/null | head -n 12000 || true)
fi
for f in /etc/apache2/sites-enabled/* /etc/apache2/sites-available/* /etc/httpd/conf.d/* /etc/httpd/conf/*; do
  [ -f "$f" ] || continue
  while IFS= read -r line; do
    p="$(printf '%s' "$line" | sed -nE 's/^[[:space:]]*SSLCertificateFile[[:space:]]+(.+)/\1/p' | tr -d '"')"
    [ -n "$p" ] && add_cert "$p"
  done < <(grep -RInhE '^[[:space:]]*SSLCertificateFile[[:space:]]+' "$f" 2>/dev/null || true)
done

if [ "${#CERTS[@]}" -eq 0 ]; then
  echo "No cert paths extracted from configs."
else
  h2 "Referenced certificate expiry"
  for c in "${CERTS[@]}"; do
    echo "==> $c"
    if need_cmd openssl; then
      openssl x509 -in "$c" -noout -subject -issuer -dates 2>/dev/null || echo "  openssl failed (not PEM x509?)"
    else
      echo "  openssl not installed"
    fi
  done
fi

# --------------- 9) localhost probes (safe) ---------------
h1 "9) LOCALHOST HTTP(S) PROBES (quick curl HEAD; capped)"

if need_cmd curl; then
  if need_cmd ss; then
    PORTS="$(ss -tulpen 2>/dev/null | awk '/LISTEN/ && $5 ~ /:[0-9]+$/ {print $5}' | sed -E 's/.*:([0-9]+)$/\1/' | sort -n | uniq)"
  elif need_cmd netstat; then
    PORTS="$(netstat -tulpen 2>/dev/null | awk '/LISTEN/ {print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | sort -n | uniq)"
  else
    PORTS=""
  fi

  echo "Detected listener ports:"
  echo "$PORTS" | tr '\n' ' '; echo

  CANDIDATES="$(printf '%s\n' 80 443 8080 8443 8000 8008 8888 5000 3000 3001 9090 9200 5601 15672 1880; echo "$PORTS")"
  CANDIDATES="$(printf '%s\n' $CANDIDATES | awk '$1 ~ /^[0-9]+$/ {print $1}' | sort -n | uniq | head -n 30)"

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    proto="http"
    if [ "$p" = "443" ] || [ "$p" = "8443" ]; then proto="https"; fi
    h2 "curl ${proto}://127.0.0.1:${p}/ (HEAD; timeout ${TIMEOUT_SECS}s)"
    timeout_cmd curl -skI --max-time "$TIMEOUT_SECS" "${proto}://127.0.0.1:${p}/" | sed -n '1,18p' || true
  done <<< "$CANDIDATES"
else
  echo "curl not installed; skipping."
fi

# --------------- 10) containers ---------------
h1 "10) CONTAINERS (docker/podman quick view)"

if need_cmd docker; then
  run "docker ps (no-trunc)" docker ps --no-trunc
  run "docker ports view" bash -lc 'docker ps --format "table {{.Names}}\t{{.Ports}}" 2>/dev/null || true'
  run "docker compose list" bash -lc 'docker compose ls 2>/dev/null || true'
fi
if need_cmd podman; then
  run "podman ps (no-trunc)" podman ps --no-trunc
fi

# --------------- 11) quick logs ---------------
h1 "11) LOG QUICKLOOK (last few minutes; capped)"

if need_cmd journalctl; then
  run "journalctl nginx (last 10m; cap ${MAX_JOURNAL})" bash -lc "journalctl -u nginx --since '10 min ago' 2>/dev/null | tail -n ${MAX_JOURNAL} || true"
  run "journalctl apache2 (last 10m; cap ${MAX_JOURNAL})" bash -lc "journalctl -u apache2 --since '10 min ago' 2>/dev/null | tail -n ${MAX_JOURNAL} || true"
  run "journalctl httpd (last 10m; cap ${MAX_JOURNAL})" bash -lc "journalctl -u httpd --since '10 min ago' 2>/dev/null | tail -n ${MAX_JOURNAL} || true"
  run "journalctl php-fpm (last 10m; cap ${MAX_JOURNAL})" bash -lc "journalctl -u php-fpm --since '10 min ago' 2>/dev/null | tail -n ${MAX_JOURNAL} || true"
fi

for f in /var/log/nginx/access.log /var/log/nginx/error.log /var/log/apache2/access.log /var/log/apache2/error.log /var/log/httpd/access_log /var/log/httpd/error_log; do
  [ -f "$f" ] || continue
  run "Tail $f (last 80 lines)" bash -lc "tail -n 80 \"$f\""
done

if [ -f /var/log/auth.log ]; then
  run "Auth log (last 100)" bash -lc 'tail -n 100 /var/log/auth.log'
elif [ -f /var/log/secure ]; then
  run "Secure log (last 100)" bash -lc 'tail -n 100 /var/log/secure'
fi

h1 "DONE — $(ts)"
echo "Tip: sudo bash web_triage.sh | tee /root/web_triage_$(hostname)_$(date +%Y%m%d_%H%M%S).log"
