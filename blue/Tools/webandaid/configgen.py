"""
Copyright (c) 2025 Yuliang Huang <https://gitlab.com/yhuang885/>

Licensed under the Apache License 2.0.
"""

import os
import pathlib
import random
import string
import sys
import typing


HEADER_BLOCK: str = '''{
		order coraza_waf before reverse_proxy
}

'''

INTERNAL_PORT_START: int = 41054

def main(argv: list[str]) -> int:
    print("WARNING: If the file \"Caddyfile\" exists, this script *will* overwrite it!")
    internal_port: int = random.randint(1024, 48128)  # Initialize to a random port.
    
    port_mappings: dict[int, int] = {}
    
    while True:
        port_number: int = -1
        while True:
            port_number_str: str = input("Enter the port number of the service to firewall: ").strip()
            try:
                port_number = int(port_number_str)
                if 0 <= port_number < 65536:
                    break
                print("Expected an integer between 0 and 65535, but got " + port_number_str)
            except ValueError:
                print("ERROR: Please enter a valid integer between 0 and 65535 inclusive, not \"" + 
                        port_number_str + "\"")
        
        tls_cert_path_str: str = input("Please enter the absolute path to the TLS certificate. " + 
                "Leave blank if no certificate. ")
        tls_cert_path: typing.Optional[pathlib.Path] = None
        tls_key_path: typing.Optional[pathlib.Path] = None
        if tls_cert_path_str != "":
            tls_cert_present = True
            tls_cert_path = pathlib.Path(tls_cert_path_str).resolve()
            while True:
                tls_key_path_str: str = input("Please enter the absolute path to the TLS key. ")
                if tls_key_path_str != "":
                    tls_key_path = pathlib.Path(tls_key_path_str).resolve()
                    break
                print("ERROR: Please enter a valid path, not \"" + str(tls_key_path_str) + "\"")
        
        # Use the "Caddyfile" template to create a Caddyfile.
        server_config_template: str = ""
        with open("configgen-server.tpl") as caddyfile_template_file:
            server_config_template = caddyfile_template_file.read()
        
        # Write the header line if the file doesn't already exist.
        try:
            with open("Caddyfile", 'x') as caddy_file:
                caddy_file.write(HEADER_BLOCK)
                # Since the file doesn't exist, initialize to a fixed starting port.
                internal_port = INTERNAL_PORT_START
        except FileExistsError:
            pass
        
        # Now write the rest of the file.
        with open("Caddyfile", 'a') as caddy_file:
            caddy_file.write(string.Template(server_config_template).substitute(
                protocol="http" if tls_cert_path is None else "https",
                externport=str(port_number),
                internport=internal_port,
                tlscomment="# " if tls_cert_path is None else "",
                tlscertpath=os.devnull if tls_cert_path is None else str(tls_cert_path),
                tlskeypath=os.devnull if tls_key_path is None else str(tls_key_path),
            ))
        
        port_mappings[port_number] = internal_port
        
        internal_port += 1
        
        if input("\nDo you have more servers to add? [y/N] ").strip().lower() != "y":
            break
    
    print("\n\nDon't forget to change the ports of the services as follows:")
    for i, port_number in enumerate(port_mappings):
        print(str(i) + ". Move service on port " + str(port_number) + 
                " to port " + str(port_mappings[port_number]))
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
