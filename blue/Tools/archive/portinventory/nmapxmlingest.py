import argparse
import pathlib
import sqlite3
import sys
import typing
import xml.etree.ElementTree as ElementTree

def main(argv: list[str]) -> int:
    argparser: argparse.ArgumentParser = argparse.ArgumentParser()
    argparser.add_argument("--sqlite-db", type=pathlib.Path,
                           default="nmapports.db",
                           help="The database file with the ports.")
    argparser.add_argument("nmap_xml_file", type=pathlib.Path,
                           help="The XML file outputted from Nmap")
    parsedargs: dict[str, typing.Any] = vars(argparser.parse_args(argv[1:]))


    nmap_ports_db = sqlite3.connect(str(parsedargs["sqlite_db"]))
    nmap_ports_db.execute("CREATE TABLE IF NOT EXISTS hosts (" + 
            "ip TEXT NOT NULL, hostname TEXT, " + 
            "os TEXT, osconf INTEGER, scantime INTEGER NOT NULL, " + 
            "PRIMARY KEY(ip));")
    nmap_ports_db.execute("CREATE TABLE IF NOT EXISTS ports (" + 
            "ip TEXT NOT NULL, protocol TEXT NOT NULL, " + 
            "port INTEGER NOT NULL, service TEXT, " + 
            "tunnel TEXT, servicever TEXT, " + 
            "serviceconf INTEGER, PRIMARY KEY(ip, protocol, port));")
    nmap_ports_db.commit()
    nmap_root = ElementTree.parse(parsedargs["nmap_xml_file"])
    runstats_tag: typing.Optional[ElementTree.Element] = nmap_root.find("runstats")
    finished_tag: typing.Optional[ElementTree.Element] = None
    if runstats_tag is not None:
        finished_tag = runstats_tag.find("finished")
    if finished_tag is None:
        raise ValueError("Attempted to ingest an incomplete scan " + 
                         "(<finished> tag missing)")
    assert finished_tag is not None
    scan_time_utc: int = int(finished_tag.attrib["time"].strip())
    for host_tag in nmap_root.findall("host"):
        address_tag: typing.Optional[ElementTree.Element] = \
                host_tag.find("address")
        if address_tag is None:
            # No IP returned - not sure what to do. Skip.
            continue
        host_ip_address: str = address_tag.attrib["addr"]
        nmap_ports_db.execute("INSERT INTO hosts (ip, scantime) " + 
                              "VALUES (?, ?) ON CONFLICT DO " + 
                              "UPDATE SET scantime=excluded.scantime;", 
                              (host_ip_address, scan_time_utc))

        hostnames_tag: typing.Optional[ElementTree.Element] = \
                host_tag.find("hostnames")
        if hostnames_tag is not None:
            for hostname_tag in hostnames_tag.findall("hostname"):
                hostname_str = hostname_tag.attrib["name"]
                nmap_ports_db.execute("UPDATE hosts SET hostname=? " + 
                        "WHERE ip=?", (hostname_tag.attrib["name"], 
                        host_ip_address))
                break

        ports_tag: typing.Optional[ElementTree.Element] = \
                host_tag.find("ports")
        if ports_tag is not None:
            nmap_ports_db.execute("DELETE FROM ports WHERE ip=?",
                                  (host_ip_address,))
            for port_tag in ports_tag.findall("port"):
                port_open: bool = False
                port_state_tag: typing.Optional[ElementTree.Element] = \
                        port_tag.find("state")
                if port_state_tag is not None and \
                        port_state_tag.attrib["state"] == "open":
                    port_open = True

                ip_port_tuple: tuple = (
                    host_ip_address, 
                    port_tag.attrib["protocol"], 
                    int(port_tag.attrib["portid"])
                )
                """Tuple with the IP, protocol, and port"""
                if port_open:
                    nmap_ports_db.execute("INSERT INTO ports (ip, " + 
                            "protocol, port) VALUES (?, ?, ?);", ip_port_tuple)
                port_service_tag: typing.Optional[ElementTree.Element] = \
                        port_tag.find("service")
                if port_service_tag is not None:
                    nmap_ports_db.execute("UPDATE ports SET " + 
                            "service=?,serviceconf=? WHERE " + 
                            "ip=? AND protocol=? AND port=?;", 
                            (port_service_tag.attrib["name"], 
                             port_service_tag.attrib["conf"]) + ip_port_tuple)
                    if "tunnel" in port_service_tag.attrib:
                        nmap_ports_db.execute("UPDATE ports SET " + 
                                "tunnel=? WHERE " + 
                                "ip=? AND protocol=? AND port=?;",
                                (port_service_tag.attrib["tunnel"],) + 
                                ip_port_tuple)
                    else:
                        # Set tunnel to NULL if no tunnel
                        nmap_ports_db.execute("UPDATE ports SET " + 
                                "tunnel=? WHERE " + 
                                "ip=? AND protocol=? AND port=?;",
                                (None,) + 
                                ip_port_tuple)
                    service_version_str: str = ""
                    if "product" in port_service_tag.attrib:
                        service_version_str += port_service_tag.attrib["product"]
                    if "version" in port_service_tag.attrib:
                        service_version_str += " " + \
                                port_service_tag.attrib["version"]
                    if "extrainfo" in port_service_tag.attrib:
                        service_version_str += " (" + \
                                port_service_tag.attrib["extrainfo"] + ")"
                    if service_version_str.strip() != "":
                        nmap_ports_db.execute("UPDATE ports SET " + 
                                "servicever=? WHERE " + 
                                "ip=? AND protocol=? AND port=?;",
                                (service_version_str,) + ip_port_tuple)
        os_tag: typing.Optional[ElementTree.Element] = \
                host_tag.find("os")
        if os_tag is not None:
            best_os_match: str = ""
            best_os_match_acc: typing.Optional[int] = None
            """Accuracy of the best OS match"""
            for osmatch_tag in os_tag.findall("osmatch"):
                osmatch_accuracy: int = int(osmatch_tag.attrib["accuracy"])
                if best_os_match_acc is None or \
                        osmatch_accuracy > best_os_match_acc:
                    best_os_match = osmatch_tag.attrib["name"]
                    best_os_match_acc = osmatch_accuracy
            nmap_ports_db.execute("UPDATE hosts SET os=?,osconf=? " + 
                "WHERE ip=?;", (best_os_match, best_os_match_acc, 
                                host_ip_address))
    nmap_ports_db.commit()

    nmap_ports_db.close()

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
