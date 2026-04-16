import argparse
import pathlib
import sqlite3
import sys
import typing

def main(argv: list[str]) -> int:
    argparser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Modifies an Uptime Kuma SQLite database with the " + 
                "scanned ports",    
    )
    argparser.add_argument("kuma_db", type=pathlib.Path,
            help="Path to the Uptime Kuma SQLite file (kuma.db)")
    parsedargs: dict[str, typing.Any] = vars(argparser.parse_args(argv[1:]))

    kuma_database: sqlite3.Connection = sqlite3.connect(str(parsedargs["kuma_db"]))
    columns_to_select_str: tuple[str, ...] = (
        "name", "active", "user_id", "interval", "url", "type", 
        "weight", "hostname", "port", "created_date", 
        "maxretries", "ignore_tls", "upside_down", "maxredirects",
        "accepted_statuscodes_json", "dns_resolve_type", "dns_resolve_server",
        "retry_interval", "method", "docker_container", 
        "expiry_notification", "mqtt_topic", "mqtt_success_message",
        "mqtt_username", "mqtt_password", "grpc_enable_tls", 
        "resend_interval", "packet_size", 
        "invert_keyword", "json_path", "kafka_producer_brokers", 
        "kafka_producer_sasl_options", "oauth_auth_method", "timeout",
        "gamedig_given_port_only", "kafka_producer_ssl", 
        "kafka_producer_allow_auto_topic_creation", "mqtt_check_type",
        "snmp_version", "json_path_operator", "cache_bust", "conditions",
        "rabbitmq_nodes", "rabbitmq_username", "rabbitmq_password", 
        "ping_count", "ping_numeric", "ping_per_request_timeout", 
        "mqtt_websocket_path",
    )
    default_entry_values: dict[str, typing.Any] = {}
    for row in kuma_database.execute("SELECT " + 
            ",".join(columns_to_select_str) + " FROM monitor LIMIT 1"):
        default_entry_values = dict(zip(columns_to_select_str, row))
        break
    if not default_entry_values:
        raise ValueError("Before running this tool, first initialize " + 
                         "Uptime Kuma and add 1 monitor. Then, stop " + 
                         "the server. This tool must be " + 
                         "run while Uptime Kuma server is stopped.")

    def insert_into_monitor_table(
            values_to_insert: dict[str, typing.Any]) -> None:
        """
        Inserts certain values into the monitor table in kuma.db

        :param values_to_insert: A dict containing the values to insert.
        :raises ValueError: If keys that do not exiset in 
        `columns_to_select_str` exist in `values_to_insert`.
        """
        entry_to_insert: dict[str, typing.Any] = default_entry_values.copy()
        entry_to_insert |= values_to_insert
        if len(entry_to_insert) != len(default_entry_values):
            raise ValueError("Found extra keys in values_to_insert: " +
                    ", ".join(set(entry_to_insert) - set(default_entry_values)))
        kuma_database_sql_query: str = "INSERT INTO monitor (" + \
                ','.join(columns_to_select_str) + ") VALUES (" + \
                ','.join(['?'] * len(columns_to_select_str)) + ");"
        #print(kuma_database_sql_query)
        #print(tuple(entry_to_insert.values()))
        kuma_database.execute(kuma_database_sql_query, 
                tuple(entry_to_insert.values()))

    nmap_database: sqlite3.Connection = sqlite3.connect("nmapports.db")
    for ip_addr, protocol, port_num, port_svc, port_tunnel, port_svc_conf \
            in nmap_database.execute("SELECT ip, protocol, port, service, " + 
                                     "tunnel, serviceconf FROM ports;"):
        if port_svc == "http" and port_svc_conf > 4:
            # Add an HTTP monitor. First check if one exists already.
            url_protocol: str = "http"
            if port_tunnel == "ssl":
                url_protocol = "https"
            url_to_add: str = url_protocol + "://" + ip_addr + ":" + str(port_num) + "/"
            url_in_database: bool = False
            """Whether the URL we want to add is already in the database"""
            for _ in kuma_database.execute("SELECT 1 FROM monitor " + 
                    "WHERE type='http' AND url=? LIMIT 1", (url_to_add,)):
                url_in_database = True
                break
            if not url_in_database:
                # Insert the URL into the database
                insert_into_monitor_table({
                    "name": ip_addr + ":" + str(port_num) + " HTTP/S",
                    "interval": 30,
                    "url": url_to_add,
                    "type": "http",
                    "ignore_tls": 1,
                    "timeout": 18,
                    "retry_interval": 20,
                })
        elif protocol.lower() == "tcp":
            # Add a TCP monitor. First check if one exists already.
            port_in_database: bool = False
            for _ in kuma_database.execute("SELECT 1 FROM monitor " + 
                    "WHERE type='port' AND hostname=? AND port=? LIMIT 1", 
                    (ip_addr, port_num)):
                port_in_database = True
                break
            if not port_in_database:
                # Insert the port into the database
                insert_into_monitor_table({
                    "name": ip_addr + " " + str(port_num) + "/tcp (" + 
                            (port_svc if port_svc_conf > 4 else "unknown") + ")",
                    "interval": 30,
                    "type": "port",
                    "hostname": ip_addr,
                    "port": port_num,
                    "timeout": 18,
                    "retry_interval": 20,
                })

    for ip_addr, hostname, os_str in nmap_database.execute(
            "SELECT ip, hostname, os FROM hosts;"):
        # Add an ICMP monitor for this IP, after checking if one exists
        host_in_database: bool = False
        for _ in kuma_database.execute("SELECT 1 FROM monitor " + 
                "WHERE type='ping' AND hostname=? LIMIT 1",
                (ip_addr,)):
            host_in_database = True
            break
        if not host_in_database:
            # Insert the host into the database
            insert_into_monitor_table({
                "name": ip_addr + " ICMP (" + ("<unknown>" if hostname is None 
                        else hostname) + " - " + 
                        ("<unknown>" if os_str is None else os_str) + ")",
                "interval": 30,
                "type": "ping",
                "hostname": ip_addr,
                "timeout": 18,
                "retry_interval": 20,
            })

    kuma_database.commit()

    nmap_database.close()
    kuma_database.close()

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
