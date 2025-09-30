#!/bin/bash

# Prompt the user for input
read -p "Enter the domain name: " domain
read -p "Enter the IP address (of name server): " ip_address
read -p "Enter the name of the user on the DNS server: " username

# Define the paths
zones_folder="/etc/bind/zones"
forward_file="$zones_folder/forward.$domain"
reverse_file="$zones_folder/reverse.$domain"

# Check if the zones folder exists, create it if not
if [ ! -d "$zones_folder" ]; then
    sudo mkdir -p "$zones_folder"
fi

# Create the forward lookup file
sudo bash -c "cat <<EOF > $forward_file
\$TTL 86400
@   IN  SOA  $domain  root (
                    $(date +%Y%m%d%H) ; Serial
                    604800         ; Refresh
                    86400         ; Retry
                    2419200       ; Expire
                    86400 )      ; Minimum TTL

; Name Server Information
@       IN  NS  $username
ns1     IN  A   $ip_address
www     IN  A   $ip_address
EOF"
# Create the reverse lookup file
sudo bash -c "cat <<EOF > $reverse_file
\$TTL 86400
@   IN  SOA $domain. root.$domain. (
                    $(date +%Y%m%d%H) ; Serial
                    3600         ; Refresh
                    1800         ; Retry
                    604800       ; Expire
                    86400 )      ; Minimum TTL

; Name Server Information
@       IN  NS  $username.
$(echo $ip_address | awk -F. '{print $4}')  IN  PTR  www.$domain.
$(echo $ip_address | awk -F. '{print $4}')  IN  PTR  ns1.$domain.
EOF"

# Display a success message
echo "Forward lookup file created successfully at $forward_file."
echo "Manual addition of subdomains is REQUIRED for both forward and reverse lookups!"
