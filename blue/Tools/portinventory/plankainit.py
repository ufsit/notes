import argparse
import configparser
import random
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
    #print(api_token_request.text)
    api_token_request.raise_for_status()
    api_token: str = api_token_request.json()["item"]

    users_request: requests.Response = requests.get(
        base_url + "/users",
        headers={
            "Authorization": "Bearer " + api_token,
        },
    )
    users_json = users_request.json()
    existing_users: set[str] = set()
    """A set of users that already exist"""
    for user_dict in users_json["items"]:
        existing_users.add(user_dict["username"])

    users_to_create: set[str] = set()
    with open("plankausers.txt", "r") as planka_users_file:
        for user_to_create in planka_users_file:
            users_to_create.add(user_to_create.strip())

    users_to_create -= existing_users
    for user_to_create in users_to_create:
        user_create_request: requests.Response = requests.post(
            base_url + "/users",
            headers={
                "Authorization": "Bearer " + api_token,
            },
            data={
                "email": user_to_create + "@test.test",
                "password": "ChangeMe123!",
                "role": "admin",
                "name": user_to_create,
                "username": user_to_create,
                "language": "en-US",
            }
        )
        print(user_create_request.text)

    # TODO Create a project and board as well.

    print("\nCreating project...")
    project_id: typing.Optional[str] = None
    project_query_request: requests.Response = requests.get(
        base_url + "/projects",
        headers={
            "Authorization": "Bearer " + api_token,
        },
    )
    for project_dict in project_query_request.json()["items"]:
        if project_dict["name"] == "Ports":
            project_id = project_dict["id"]
    if project_id is None:
        project_create_request: requests.Response = requests.post(
            base_url + "/projects",
            headers={
                "Authorization": "Bearer " + api_token,
            },
            data={
                "type": "shared",
                "name": "Ports",
                "description": "A project for storing port information. " + 
                       "DO NOT MODIFY THE TITLE OF THIS PROJECT!",
            },
        )
        print(project_create_request.text)
        project_id = project_create_request.json()["item"]["id"]

    assert project_id is not None, "Possible error when fetching project"
    print("\nCreating board within project...")
    board_id: typing.Optional[str] = None
    project_fetch_request: requests.Response = requests.get(
        base_url + "/projects/" + project_id,
        headers={
            "Authorization": "Bearer " + api_token,
        },
    )
    try:
        for board_json in project_fetch_request.json()["included"]["boards"]:
            if board_json["name"] == "Ports":
                board_id = board_json["id"]
    except KeyError:
        pass
    if board_id is None:
        # Ensure the board is only created once.
        board_create_request: requests.Response = requests.post(
            base_url + "/projects/" + project_id + "/boards",
            headers={
                "Authorization": "Bearer " + api_token,
            },
            data={
                "position": random.randint(0,65536),
                "name": "Ports",
            }
        )
        print(board_create_request.text)
        board_id = board_create_request.json()["item"]["id"]

    assert board_id is not None

    print("\nMaking everyone a project manager...")
    user_ids: list[str] = []
    users_request = requests.get(
        base_url + "/users",
        headers={
            "Authorization": "Bearer " + api_token,
        },
    )
    for user_json in users_request.json()["items"]:
        if user_json["role"] in ("admin","projectOwner"):
            project_manager_request: requests.Response = requests.post(
                base_url + "/projects/" + project_id + "/project-managers",
                headers={
                    "Authorization": "Bearer " + api_token,
                },
                data={
                    "userId": user_json["id"],
                },
            )
            print(project_manager_request.text)
        board_editor_request: requests.Response = requests.post(
            base_url + "/boards/" + board_id + "/board-memberships",
            headers={
                "Authorization": "Bearer " + api_token,
            },
            json={
                "userId": user_json["id"],
                "role": "editor",
                "canComment": True,
            },
        )
        print(board_editor_request.text)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
