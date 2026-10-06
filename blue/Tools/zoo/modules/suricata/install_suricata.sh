#!/bin/sh

set -e

echo "[Suricata] Starting installation/configuration..."

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Install Suricata
if command -v suricata >/dev/null 2>&1; then
    echo "[Suricata] Suricata is already installed."
else
    echo "[Suricata] Installing Suricata..."

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y suricata
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y suricata
        elif command -v yum >/dev/null 2>&1; then
            yum install -y suricata
        elif command -v zypper >/dev/null 2>&1; then
            zypper --non-interactive install suricata
        elif command -v apk >/dev/null 2>&1; then
            apk add suricata
        else
            echo "[Suricata] Unsupported package manager."
            exit 1
        fi
fi

echo "[Suricata] Installed version:"
suricata -V || true

# Update Suricata rules
if command -v suricata-update >/dev/null 2>&1; then
        echo "[Suricata] Updating detection rules..."
        suricata-update || echo "[Suricata] Rule update failed; continuing."
fi

# Verify EVE JSON configuration
SURICATA_CONFIG="/etc/suricata/suricata.yaml"

if [ ! -f "$SURICATA_CONFIG" ]; then
    echo "[Suricata] Could not find $SURICATA_CONFIG"
        exit 1
fi

echo "[Suricata] Checking eve.json configuration..."

if grep -q "filename: eve.json" "$SURICATA_CONFIG"; then
        echo "[Suricata] eve.json output is configured."
else
    echo "[Suricata] WARNING: eve.json output was not found in Suricata config."
fi

# Start Suricata
if command -v systemctl >/dev/null 2>&1; then
        systemctl enable suricata || true
        systemctl restart suricata
elif command -v rc-service >/dev/null 2>&1; then
        rc-update add suricata default || true
        rc-service suricata restart
elif command -v service >/dev/null 2>&1; then
        service suricata restart
fi

# Connect eve.json to Filebeat
if command -v filebeat >/dev/null 2>&1; then
        echo "[Suricata] Filebeat detected. Configuring Suricata module..."

        filebeat modules enable suricata || true

        FILEBEAT_SURICATA="/etc/filebeat/modules.d/suricata.yml"

        if [ -f "$FILEBEAT_SURICATA" ]; then
            cat > "$FILEBEAT_SURICATA" <<'EOF'
- module: suricata
  eve:
        enabled: true
        var.paths: ["/var/log/suricata/eve.json"]
EOF

        echo "[Suricata] Testing Filebeat configuration..."

            if filebeat test config -c /etc/filebeat/filebeat.yml; then
                echo "[Suricata] Filebeat configuration is valid."
            else
                    echo "[Suricata] Filebeat configuration test failed."
                    exit 1
            fi

            if command -v systemctl >/dev/null 2>&1; then
                    systemctl restart filebeat
            elif command -v rc-service >/dev/null 2>&1; then
                    rc-service filebeat restart
            elif command -v service >/dev/null 2>&1; then
                    service filebeat restart
            fi

            echo "[Suricata] eve.json is now connected to Filebeat."
        else
            echo "[Suricata] Filebeat Suricata module config was not found."
            exit 1
        fi
else
        echo "[Suricata] Filebeat is not installed."
        echo "[Suricata] Run the ELK deployment module first, then rerun Suricata."
fi

echo
echo "[Suricata] Deployment complete."
echo "[Suricata] EVE log: /var/log/suricata/eve.json"
