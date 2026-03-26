import cmd
import configparser
import ipaddress
from ipaddress import IPv4Address, IPv6Address, IPv4Network, IPv6Network
import os
import socket
import sqlite3
import sys
import typing

CREATE_IP_TABLE_STATEMENT: str = \
'''CREATE TABLE IF NOT EXISTS ipaddress (
    ip TEXT NOT NULL,
    asn INTEGER,
    prefix TEXT,
    cc TEXT,
    rir TEXT,
    isp TEXT,
    rdns TEXT,
    score INTEGER NOT NULL,
    global INTEGER NOT NULL CHECK(global = 0 OR global = 1),
    PRIMARY KEY(ip)
);'''

class IpCatalogShell(cmd.Cmd):
    intro: str = "Type ? or HELP for help."
    prompt: str = "> "
    database: typing.Optional[sqlite3.Connection] = None
    database_path: str = os.devnull
    bgp_tools_lookup: bool = True
    """Whether to check IPs with bgp.tools"""
    rdns_lookup: bool = True
    """Whether to check reverse DNS records on the IPs"""
 
    def do_add(self, arg) -> None:
        """
        Adds an IP. b = benign, pb = probably benign, s = suspicious, m = malicious
        If IP already in database, will update instead.
        ADD <IP> <CLASSIFICATION>
        ADD 127.0.0.1 b
        """
        classification_to_score: dict[str, int] = {'b': -3, 'pb': -1, 's': 1, 'm': 3}
        """Converts the argument to a score"""

        argv: list[str] = arg.split(' ')
        if len(argv) != 2:
            print(f"ERROR: Wrong number of arguments, expected 2, got {len(argv)}")
            return 

        ip_address: typing.Optional[typing.Union[IPv4Address, IPv6Address]] = None
        try:
            ip_address = ipaddress.ip_address(argv[0])
        except ValueError:
            pass

        if ip_address is None:
            print(f"ERROR: Invalid IP address {argv[0]}")
            return

        if argv[1] not in classification_to_score:
            print(f"ERROR: Invalid classification {argv[1]}, must be one of (" +
                  ", ".join(tuple(classification_to_score)) + ")")
            return

        self.init_db()

        reverse_dns_entry: typing.Optional[str] = None
        if self.rdns_lookup:
            try:
                reverse_dns_entry, _, _ = socket.gethostbyaddr(str(ip_address))
            except socket.herror:
                pass
            print("rDNS:", reverse_dns_entry)

        asn: typing.Optional[str] = None
        prefix: typing.Optional[str] = None
        cc: typing.Optional[str] = None
        rir: typing.Optional[str] = None
        isp: typing.Optional[str] = None
        if self.bgp_tools_lookup:
            if ip_address.is_global:
                try:
                    bgp_tools_sock: socket.socket = socket.socket(
                            family=socket.AF_INET, type=socket.SOCK_STREAM)
                    bgp_tools_sock.settimeout(5)
                    bgp_tools_sock.connect(("bgp.tools", 43))
                    bgp_tools_sock.send(
                        f"begin\n{ip_address}\nend\n".encode("utf-8")
                    )
                    bgp_tools_received_data: bytearray = bytearray()
                    while True:
                        bgp_tools_recv_chunk = bgp_tools_sock.recv(4096)
                        bgp_tools_received_data.extend(bgp_tools_recv_chunk)
                        if len(bgp_tools_recv_chunk) < 4096:
                            break
                    bgp_tools_str_raw: str = bgp_tools_received_data.decode("utf-8")
                    """The unprocessed string returned from bgp.tools"""
                    bgp_tools_fields: list[str] = bgp_tools_str_raw.split('|')
                    if len(bgp_tools_fields) == 7:
                        asn = bgp_tools_fields[0].strip()
                        prefix = bgp_tools_fields[2].strip()
                        cc = bgp_tools_fields[3].strip()
                        rir = bgp_tools_fields[4].strip()
                        isp = bgp_tools_fields[6].strip()
                    else:
                        print("WARNING: bgp.tools returned corrupt response")
                except TimeoutError:
                    print("WARNING: Timed out when contacting bgp.tools.")

        assert self.database is not None
        self.database.execute("INSERT INTO ipaddress " + 
                "(ip, asn, prefix, cc, rir, isp, rdns, score, global) " + 
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO " + 
                "UPDATE SET asn=excluded.asn, prefix=excluded.prefix, " + 
                "cc=excluded.cc, rir=excluded.rir, isp=excluded.isp, " + 
                "rdns=excluded.rdns, score=excluded.score, " + 
                "global=excluded.global;", (
            str(ip_address),
            asn,
            prefix,
            cc,
            rir,
            isp,
            reverse_dns_entry,
            classification_to_score[argv[1]],
            int(ip_address.is_global),
        ))
        self.database.commit()

    def do_del(self, arg) -> None:
        """
        Removes an IP from the database. Support the use of wildcards to remove
        multiple.
        del <IP_ADDRESS>
        del 127.0.0.1
        """
        if arg.strip() == "":
            print("Expected 1 argument, got 0.")
            return
        self.init_db()
        assert self.database is not None
        self.database.execute("DELETE FROM ipaddress WHERE ip LIKE ?", (arg,))
        self.database.commit()

    def do_exit(self, arg) -> bool:
        """
        Exits the interactive shell. Takes no arguments.
        """
        if self.database is not None:
            self.database.close()
        return True

    def do_get(self, arg) -> None:
        """
        Gets the known IP addresses. Omit the argument to get all. You can use
        SQL wildcards like % and *.
        get
        get 127.0.0.1
        get 127.0.%
        """
        if arg.strip() == "":
            arg = '%'
        self.init_db()
        assert self.database is not None
        for row in self.database.execute("SELECT ip, asn, cc, isp, rdns, score " + 
                                         "FROM ipaddress WHERE ip LIKE ?;",
                                         (arg,)):
            row_temp: list[str] = []
            for val in row:
                row_temp.append("NA" if val is None else str(val))
            row = tuple(row_temp)
            print(row[0].ljust(20)[:20] + "|" + row[1].ljust(10)[:10] + 
                  "|" + row[2].ljust(2)[:2] + "|" + row[3].ljust(16)[:16] + 
                  "|" + row[4].ljust(25)[:25] + "|" + row[5].ljust(2)[:2])

    def do_subnet4(self, arg) -> None:
        """
        Gets IPv4 subnets by length and analyzes for malicious traffic.
        subnet4 <SUBNET_LENGTH>
        """
        subnet_length: int = 0
        try:
            subnet_length = int(arg.strip())
        except ValueError:
            print(f"ERROR: SUBNET_LENGTH must be an integer, not {arg}")
            return
        if subnet_length < 0 or subnet_length > 32:
            print("ERROR: SUBNET_LENGTR must be an integer between 0 and 32")
            return
        self.print_subnet(subnet_length, False)

    def do_subnet6(self, arg) -> None:
        """
        Gets IPv6 subnets by length and analyzes for malicious traffic
        subnet6 <SUBNET_LENGTH>
        """
        subnet_length: int = 0
        try:
            subnet_length = int(arg.strip())
        except ValueError:
            print(f"ERROR: SUBNET_LENGTH must be an integer, not {arg}")
            return
        if subnet_length < 0 or subnet_length > 128:
            print("ERROR: SUBNET_LENGTR must be an integer between 0 and 128")
            return
        self.print_subnet(subnet_length, True)

    def print_subnet(self, subnet_length: int, ipv6: bool) -> None:
        """
        Prints the subnet information.

        :param ipv6: If True, will filter for IPv6 addresses.
        """
        print("Subnet: Score  B/PB/S/M")
        target_ip_version: int = 4
        if ipv6:
            target_ip_version = 6
        self.init_db()
        assert self.database is not None
        network_scores: dict[str, list[int]] = {}
        """Maps network to [count, b, pb, s, m]"""
        for ip_address_str, score in \
                self.database.execute("SELECT ip, score FROM ipaddress;"):
            ip_address_obj: typing.Union[IPv4Address, IPv6Address] = \
                    ipaddress.ip_address(ip_address_str)
            if ip_address_obj.version != target_ip_version:
                # Skip this network. Wrong IP version
                continue
            ip_network: typing.Union[IPv4Network, IPv6Network] = \
                    ipaddress.ip_network(ip_address_str)\
                    .supernet(new_prefix=subnet_length)
            network_str: str = str(ip_network)
            if network_str not in network_scores:
                network_scores[network_str] = [0, 0, 0, 0, 0]
            network_scores[network_str][0] += score
            if score == -3:
                network_scores[network_str][1] += 1
            elif score == -1:
                network_scores[network_str][2] += 1
            elif score == 1:
                network_scores[network_str][3] += 1
            elif score == 3:
                network_scores[network_str][4] += 1
        subnet_strings_sort: list[tuple[int, str]] = []
        """List to use for sorting the subnet strings"""
        for network_ip, network_score in network_scores.items():
            subnet_strings_sort.append((
                network_score[0], 
                network_ip + f": Score {network_score[0]}  " + 
                        "/".join([str(i) for i in network_score[1:]]),
            ))
        subnet_strings_sort.sort()
        for subnet_string in reversed(subnet_strings_sort):
            print(subnet_string[1])

    def init_db(self) -> None:
        """
        Initializes the database if it hasn't been initialized already.
        """
        if self.database is None:
            # Connect to the database and create the IP table if it doesn't
            # exist.
            self.database = sqlite3.connect(self.database_path)
            self.database.execute(CREATE_IP_TABLE_STATEMENT)
            self.database.commit()

def main(argv: list[str]) -> int:
    ipcatalogshell: IpCatalogShell = IpCatalogShell()
    ipcatalogshell.database_path = "ipcatalog.db"
    ipcatalogshell.cmdloop()
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
