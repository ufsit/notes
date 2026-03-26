import argparse
import configparser
import datetime
import random
import sqlite3
import sys
import typing

import requests

def main(argv: list[str]) -> int:
    plankaconfig: configparser.ConfigParser = configparser.ConfigParser()
    plankaconfig.read("plankaconfig.ini")

    base_url: str = plankaconfig["Planka"]["base_url"]
    username: str = plankaconfig["Planka"]["username"]
    password: str = plankaconfig["Planka"]["password"]

    api_token_request: requests.Response = requests.post(
            base_url + "/access-tokens",
            data={"emailOrUsername": username,
                  "password": password})
    api_token_request.raise_for_status()
    api_token: str = api_token_request.json()["item"]

    projects_request: requests.Response = requests.get(
        base_url + "/projects",
        headers={"Authorization": "Bearer " + api_token},
    )
    project_id: typing.Optional[str] = None
    board_id: typing.Optional[str] = None
    projects_json: dict = projects_request.json()
    for project_json in projects_json["items"]:
        if project_json["name"] == "Ports":
           project_id = project_json["id"]
           break
    if project_id is None:
        raise ValueError("Failed to find project \"Ports\"." + 
                         "Ensure you have run \"plankainit.py\" and try again.")
    for board_json in projects_json["included"]["boards"]:
        if board_json["projectId"] == project_id and \
                board_json["name"] == "Ports":
            board_id = board_json["id"]
            break
    if board_id is None:
        raise ValueError("Failed to find board \"Ports\"." + 
                         "Ensure you have run \"plankainit.py\" and try again.")

    board_request: requests.Response = requests.get(
        base_url + "/boards/" + board_id,
        headers={"Authorization": "Bearer " + api_token},
    )
    label_to_id: dict[str, str] = {}
    """Dict mapping labels to their IDs"""
    labels_to_add: dict[str, str] = {
            "Triage": "summer-sky", 
            "Need help": "egg-yellow", 
            "Unknown": "berry-red", 
            "HTTP": "antique-blue",
            "SQL": "modern-green", 
            "SSH": "silver-glint", 
            "FTP": "sunny-grass", 
            "LDAP": "pirate-gold", 
            "DNS": "shady-rust",
            "RDP": "silver-glint",
            "TLS": "dark-granite",
            "Well-known": "light-concrete",
    }
    """Maps labels to add to their colors"""

    # Add the labels to the board if they don't exist
    board_json = board_request.json()
    print("\nCreating labels...")
    label_name_to_id: dict[str, str] = {}
    """A dict mapping existing labels to their IDs"""
    for label_json in board_json["included"]["labels"]:
        label_name_to_id[label_json["name"].strip()] = label_json["id"]

    for label_to_add in set(labels_to_add) - set(label_name_to_id):
        label_create_request: requests.Response = requests.post(
            base_url + "/boards/" + board_id + "/labels",
            headers={"Authorization": "Bearer " + api_token},
            json={
                "position": random.randint(1,65536),
                "color": labels_to_add[label_to_add],
                "name": label_to_add,
            },
        )
        print(label_create_request.text)
        label_name_to_id[label_to_add] = \
                label_create_request.json()["item"]["id"]

    # Add the hosts as lists.
    list_name_to_id: dict[str, str] = {}
    for list_json in board_json["included"]["lists"]:
        list_name_to_id[list_json["name"]] = list_json["id"]

    host_scan_times: dict[str, int] = {}
    """Maps host_ip to Unix scan time timestamp (in UTC)"""

    # Create all the lists that don't exist.
    ports_db = sqlite3.connect("nmapports.db")
    for ip_addr, hostname, os_str, os_conf, host_scan_time_utc in \
            ports_db.execute("SELECT ip, hostname, os, osconf, scantime " + 
                             "FROM hosts"):
        host_scan_times[ip_addr] = host_scan_time_utc
        if ip_addr not in list_name_to_id:
            create_list_request: requests.Response = requests.post(
                base_url + "/boards/" + board_id + "/lists",
                headers={"Authorization": "Bearer " + api_token},
                json={
                    "type": "active",
                    "position": random.randint(1,65536),
                    "name": ip_addr,
                }
            )
            print(create_list_request.text)
            list_name_to_id[ip_addr] = create_list_request.json()["item"]["id"]

        assert ip_addr in list_name_to_id

        list_id: str = list_name_to_id[ip_addr]

        cards_request: requests.Response = requests.get(
            base_url + "/lists/" + list_id + "/cards",
            headers={"Authorization": "Bearer " + api_token},
        )
        
        hostname_card_id: typing.Optional[str] = None
        for card_json in cards_request.json()["items"]:
            if "HOST INFO FOR " in card_json["name"]:
                hostname_card_id = card_json["id"]
        print("\nUpdating hostname card...")
        if hostname_card_id is None:
            hostname_card_create_request: requests.Response = requests.post(
                base_url + "/lists/" + list_id + "/cards",
                headers={"Authorization": "Bearer " + api_token},
                json={
                    "type": "project",
                    "name": "HOST INFO FOR " + (
                        "<Unknown>" if hostname is None else hostname),
                    "position": 2,
                },
            )
            print(hostname_card_create_request.text)
            hostname_card_id = hostname_card_create_request.json()["item"]["id"]
        assert hostname_card_id is not None
        
        scan_time_str: str = datetime.datetime.fromtimestamp(
                host_scan_time_utc).astimezone()\
                .strftime("%Y-%m-%d %H:%M:%S %z")
        hostname_card_update_request: requests.Response = requests.patch(
            base_url + "/cards/" + hostname_card_id,
            headers={"Authorization": "Bearer " + api_token},
            json={
                "description": "Hostname: " + ("<Unknown>" if hostname is None 
                        else hostname) + "\nDetected OS: " + ("<Unknown>" 
                        if os_str is None else os_str) + 
                        "\nOS detection confidence: " +
                        ("NaN" if os_conf is None else str(os_conf)) + 
                        "%\n Last scanned: " + scan_time_str
            }
        )
        print(hostname_card_update_request.text)

    for list_name, list_id in list_name_to_id.items():
        if list_name not in host_scan_times:
            # Host was not scanned (or was down). Ignore for now.
            continue
        open_ports: dict[tuple[str, int], tuple[str, str, str, int]] = {}
        """
        A dict mapping (protocol, port) to 
        (service, tunnel, version, confidence)
        """
        for protocol, port, service_str, service_tunnel, service_version, \
                service_conf in \
                ports_db.execute("SELECT protocol, port, service, " +
                                 "tunnel, servicever, serviceconf " + 
                                 "FROM ports WHERE ip=?",
                                 (list_name,)):
            open_ports[(protocol, port)] = (service_str, service_tunnel, 
                                            service_version, service_conf)

        cards_request = requests.get(
            base_url + "/lists/" + list_id + "/cards",
            headers={"Authorization": "Bearer " + api_token},
        )
        existing_cards: dict[str, str] = dict()
        """A dict mapping card_title to card_id"""
        for card_json in cards_request.json()["items"]:
            existing_cards[card_json["name"]] = card_json["id"]

        print(f"\nCreating and commenting on cards for {list_name}...")
        for open_port_tuple, open_port_service in open_ports.items():
            open_port_number: int
            open_port_protocol: str
            open_port_service_str: str
            open_port_service_tunnel: typing.Optional[str]
            open_port_service_version: typing.Optional[str]
            open_port_service_conf: int
            open_port_protocol, open_port_number = open_port_tuple
            open_port_service_str, open_port_service_tunnel, \
                    open_port_service_version, open_port_service_conf = \
                    open_port_service
            open_port_str: str = f"{open_port_number}/{open_port_protocol}"

            # Create sets of labels to add to and remove from the card at the
            # end.
            card_labels_to_add: set[str] = set()
            """Names of labels to add to the card"""
            card_labels_to_remove: set[str] = set()
            """Names of labels to remove from the card"""

            if open_port_str not in existing_cards:
                # Add the card to the list.
                card_create_request: requests.Response = requests.post(
                    base_url + "/lists/" + list_id + "/cards",
                    headers={"Authorization": "Bearer " + api_token},
                    json={
                        "type": "project",
                        "name": open_port_str,
                        "position": 16 + open_port_number * 2 + \
                                int(open_port_protocol.lower() == "udp"),
                        "description": open_port_protocol.upper() + " port " +\
                                str(open_port_number)
                    },
                )
                print(card_create_request.text)
                existing_cards[open_port_str] = \
                        card_create_request.json()["item"]["id"]
                card_labels_to_add.add("Triage")

            # Add a comment to the card.
            scan_time_str = datetime.datetime.fromtimestamp(
                    host_scan_times[list_name]).astimezone()\
                    .strftime("%Y-%m-%d %H:%M:%S %z")
            open_port_conf_str: str = "unknown"
            if open_port_service_conf is not None:
                open_port_conf_str = str(open_port_service_conf * 10) + "%"
            comment_text: str = f"Open port {open_port_str} " + \
                    f"scanned at {scan_time_str}\n\nService detected as \"" + \
                    str(open_port_service_str) + "\"" + \
                    ("" if open_port_service_tunnel is None else 
                     f" (tunneled through {open_port_service_tunnel}) ") + \
                    f" with {open_port_conf_str} confidence\n\n" + \
                    "Service version: " + \
                    ("<Unknown>" if open_port_service_version is None 
                     else open_port_service_version)
            comments_request: requests.Response = requests.get(
                base_url + "/cards/" + existing_cards[open_port_str] + 
                        "/comments",
                headers={"Authorization": "Bearer " + api_token},
            )
            print(comments_request.text)

            # Only post the comment if an identical one does not already
            # exist.
            should_post_comment: bool = True
            for comment_json in comments_request.json()["items"]:
                if comment_json["text"] == comment_text:
                    should_post_comment = False
                    break
            if should_post_comment:
                comment_create_request: requests.Response = requests.post(
                    base_url + "/cards/" + existing_cards[open_port_str] + 
                            "/comments",
                    headers={"Authorization": "Bearer " + api_token},
                    json={
                        "text": comment_text,
                    },
                )
                print(comment_create_request.text)

            # Code handling service detection
            if open_port_service_conf is not None and \
                    open_port_service_conf > 4:
                service_tag_added: bool = False
                """Whether a service tag was added"""
                if "ssh" == open_port_service_str.lower():
                    card_labels_to_add.add("SSH")
                    service_tag_added = True
                if "domain" == open_port_service_str.lower():
                    card_labels_to_add.add("DNS")
                    service_tag_added = True
                if "http" in open_port_service_str.lower():
                    card_labels_to_add.add("HTTP")
                    service_tag_added = True
                if "ftp" in open_port_service_str.lower():
                    card_labels_to_add.add("FTP")
                    service_tag_added = True
                if "ldap" in open_port_service_str.lower():
                    card_labels_to_add.add("LDAP")
                    service_tag_added = True
                if "ms-wbt-server" == open_port_service_str.lower():
                    card_labels_to_add.add("RDP")
                    service_tag_added = True
                if "sql" in open_port_service_str.lower():
                    card_labels_to_add.add("SQL")
                    service_tag_added = True
                if open_port_service_tunnel is not None and \
                        "ssl" == open_port_service_tunnel:
                    card_labels_to_add.add("TLS")
                    # No service tag because anything can be wrapped in TLS
                if not service_tag_added:
                    card_labels_to_add.add("Well-known")
                card_labels_to_remove.add("Unknown")
            else:
                card_labels_to_add.add("Unknown")

            # Add labels if the service detection was high-confidence
            print(f"\nAdding/removing labels to card \"{open_port_str}\"...")
            card_get_request: requests.Response = requests.get(
                base_url + "/cards/" + existing_cards[open_port_str],
                headers={"Authorization": "Bearer " + api_token},
            )
            print(card_get_request.text)
            card_label_ids: set[str] = set()
            """A dict containig the ID of all labels associated with the card"""
            for label_json in card_get_request.json()["included"]["cardLabels"]:
                if label_json["cardId"] == existing_cards[open_port_str]:
                    card_label_ids.add(label_json["labelId"])
            for card_label_to_add in card_labels_to_add:
                label_id_to_add: str = label_name_to_id[card_label_to_add]
                if label_id_to_add not in card_label_ids:
                    card_label_add_request: requests.Response = requests.post(
                        base_url + "/cards/" + existing_cards[open_port_str] + 
                                "/card-labels",
                        headers={"Authorization": "Bearer " + api_token},
                        json={
                            "labelId": label_id_to_add,
                        },
                    )
                    print(card_label_add_request.text)
            for card_label_to_remove in card_labels_to_remove:
                label_id_to_remove: str = label_name_to_id[card_label_to_remove]
                if label_id_to_remove in card_label_ids:
                    card_label_remove_request: requests.Response = \
                            requests.delete(
                        base_url + "/cards/" + existing_cards[open_port_str] + 
                                "/card-labels/labelId:" + label_id_to_remove,
                        headers={"Authorization": "Bearer " + api_token},
                    )
                    print(card_label_remove_request.text)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
