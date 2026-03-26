#!/bin/bash

# install pip3
if ! command -v pip3 &> /dev/null; then
    if command -v apt-get &>/dev/null; then
		sudo apt-get update && sudo apt-get install -y --reinstall python3-pip
	elif command -v yum &>/dev/null; then
		sudo yum install -y python3-pip
		sudo yum reinstall python3-pip
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y python3-pip
		sudo dnf reinstall python3-pip
	elif command -v brew &>/dev/null; then
		brew install python3-pip
		brew reinstall python3-pip
    else
		echo "Could not determine a package manager."
		exit 1
	fi
fi

if ! command -v hawk_scanner &> /dev/null; then
	pip3 install hawk-scanner
fi

#docker run -it --rm -v /home/blue/injects/hawk-eye/results:/app/results -v /home/blue/injects/hawk-eye/connection.yml:/app/connection.yml -v /home/blue/injects/hawk-eye/fingerprint.yml:/app/fingerprint.yml --add-host=host.docker.internal:host-gateway rohitcoder/hawk-eye --connection /app/connection.yml --fingerprint /app/fingerprint.yml --json /app/results/results.json all

hawk_scanner all --connection /home/blue/injects/hawk-eye/connection.yml --fingerprint /home/blue/injects/hawk-eye/fingerprint.yml --json hawkeye.json