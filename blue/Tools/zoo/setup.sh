#!/bin/sh
# Detects your package manager and downloads netexec with it

detect_pm() {
        for pm in apt dnf yum pacman zypper apk brew; do
                command -v "$pm" >/dev/null 2>&1 && { echo "$pm"; return; }
        done
        echo "unsupported"
}

install_pkg() {
        case "$1" in
                apt)    sudo apt-get update && sudo apt-get install -y "$2" ;;
                dnf)    sudo dnf install -y "$2" ;;
                yum)    sudo yum install -y "$2" ;;
                pacman) sudo pacman -Sy --noconfirm "$2" ;;
                zypper) sudo zypper install -y "$2" ;;
                apk)    sudo apk add "$2" ;;
                brew)   brew install "$2" ;;
        esac
}

PM="$(detect_pm)"
if [ "$PM" = unsupported ]; then
        echo "No supported package manager found (apt/dnf/yum/pacman/zypper/apk/brew)."
        exit 2
fi

echo "Installing netexec with $PM..."
install_pkg "$PM" netexec || { echo "Install failed. netexec may not be in your distro's repos (it is in Kali)."; exit 1; }
command -v nxc >/dev/null 2>&1 && nxc --version || echo "Done. Verify with: nxc --version"
