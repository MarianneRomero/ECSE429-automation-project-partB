"""HTTP helpers for the story tests. Everything that talks to the server goes
through `call`, so every step uses the same base URL, headers and timeout."""

import os

import requests

BASE_URL = os.environ.get("TODO_API_URL", "http://localhost:4567").rstrip("/")
TIMEOUT = 5

# Collection name -> singular name used in step text ("a todo", "the category").
SINGULAR = {"todos": "todo", "projects": "project", "categories": "category"}


def call(method, path, body=None):
    """Send one JSON request."""
    return requests.request(
        method, f"{BASE_URL}{path}", headers={"Accept": "application/json"},
        json=body, timeout=TIMEOUT,
    )


def items(response, collection):
    """The list of objects in a response such as {"todos": [...]}."""
    return response.json()[collection]


def related_ids(obj, relationship):
    """Ids listed under a relationship inside an object, e.g. project["tasks"]."""
    return {ref["id"] for ref in obj.get(relationship, [])}


def link(parent, parent_id, relationship, child_id):
    return call("POST", f"/{parent}/{parent_id}/{relationship}", {"id": str(child_id)})


def snapshot():
    """The full state of the server, normalised so it can be compared with ==."""
    state = {}
    for collection in SINGULAR:
        state[collection] = {
            obj["id"]: {
                key: sorted(ref["id"] for ref in value) if isinstance(value, list) else value
                for key, value in obj.items()
            }
            for obj in items(call("GET", f"/{collection}"), collection)
        }
    return state


def not_ready_reason():
    """Why the API cannot be tested, or None when it is ready."""
    for collection in SINGULAR:
        url = f"{BASE_URL}/{collection}"
        try:
            response = call("GET", f"/{collection}")
        except requests.RequestException as error:
            return f"could not reach {url} ({type(error).__name__})"
        if response.status_code != 200:
            return f"{url} answered {response.status_code}; is this the Todo Manager?"
        try:
            body = response.json()
        except ValueError:
            return f"{url} did not answer with JSON; is this the Todo Manager?"
        if not isinstance(body, dict) or collection not in body:
            return f"{url} answered without a list of {collection}; is this the Todo Manager?"
    return None
