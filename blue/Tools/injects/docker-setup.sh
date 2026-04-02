#!/bin/bash

# install curl
if ! command -v curl &> /dev/null; then
    if command -v apt-get &>/dev/null; then
		sudo apt-get update && sudo apt-get install -y --reinstall curl
	elif command -v yum &>/dev/null; then
		sudo yum install -y curl
		sudo yum reinstall curl
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y curl
		sudo dnf reinstall curl
	elif command -v brew &>/dev/null; then
		brew install curl
		brew reinstall curl
    else
		echo "Could not determine a package manager."
		exit 1
	fi
fi
# get docker
if command -v docker &>/dev/null; then
	echo "docker here"
else
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
fi
