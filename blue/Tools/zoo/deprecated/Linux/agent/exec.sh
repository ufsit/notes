#!/bin/sh
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$(id -u)" -eq 0 ]; then
  "$script_dir/$2"
else
  (echo "$1"; echo "$1") | sudo -S "$script_dir/$2"
fi
