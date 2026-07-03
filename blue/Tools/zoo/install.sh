#!/bin/sh

# Determine the package manager
detect_package_manager() {
  if command -v apt > /dev/null; then
    echo "apt"
  elif command -v dnf > /dev/null; then
    echo "dnf"
  elif command -v yum > /dev/null; then
    echo "yum"
  elif command -v pacman > /dev/null; then
    echo "pacman"
  elif command -v zypper > /dev/null; then
    echo "zypper"
  elif command -v apk > /dev/null; then
    echo "apk"
  elif command -v brew > /dev/null; then
    echo "brew"
  else
    echo "unsupported"
  fi
}

# Check if the package is installed
is_installed() {
  case "$1" in
    apt) dpkg -s "$PACKAGE" > /dev/null 2>&1 ;;
    dnf|yum) rpm -q "$PACKAGE" > /dev/null 2>&1 ;;
    pacman) pacman -Qi "$PACKAGE" > /dev/null 2>&1 ;;
    zypper) rpm -q "$PACKAGE" > /dev/null 2>&1 ;;
    apk) apk info "$PACKAGE" > /dev/null 2>&1 ;;
    brew) brew list "$PACKAGE" > /dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

# Install the package
install_package() {
  case "$1" in
    apt) apt update && sudo apt install -y $package_list ;;
    dnf) dnf install -y $package_list ;;
    yum) yum install -y $package_list ;;
    pacman) pacman -Sy --noconfirm $package_list ;;
    zypper) zypper install -y $package_list ;;
    apk) apk add $package_list ;;
    brew) brew install $package_list ;;
    *) echo "Unsupported package manager"; exit 2 ;;
  esac
}

check() {
  PACKAGE="$1"
  if is_installed "$PM"; then
    echo "Package '$PACKAGE' is already installed."
  else
    package_list="$package_list $1"
  fi
}

PM=$(detect_package_manager)

if [ "$PM" = "unsupported" ]; then
  echo "No supported package manager found on this system."
  exit 2
fi

#package_list=""
#check nano
check nmap
check sshpass
#if [ -n "$package_list" ]; then
#  echo "Installing$package_list using $PM..."
#  install_package "$PM"
#fi
