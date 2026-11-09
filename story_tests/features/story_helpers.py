"""Helpers shared by the step modules in features/steps/.

Kept outside steps/ because behave executes every module in steps/ as a step
module; importing one step module from another would register its steps twice.
"""

import parse
from behave import register_type

from api import SINGULAR, call, items

PLURAL = {singular: plural for plural, singular in SINGULAR.items()}


@parse.with_pattern(r"todo|project|category")
def parse_resource(text):
    """'todo' -> 'todos', so steps can say "a todo" and get the collection name."""
    return PLURAL[text]


@parse.with_pattern(r"todos|projects|categories")
def parse_collection(text):
    return text


@parse.with_pattern(r'[^"]*')
def parse_text(text):
    """Quoted text that may be empty: plain {value} needs at least one character."""
    return text


register_type(Resource=parse_resource, Collection=parse_collection, Text=parse_text)


def field_value(text):
    """Table and step values arrive as strings; the API wants real booleans."""
    return {"true": True, "false": False}.get(text.lower(), text)


def create(context, collection, fields):
    """POST a new object and remember it for cleanup and lookup by title."""
    response = call("POST", f"/{collection}", fields)
    if response.status_code == 201:
        remember(context, collection, response.json())
    return response


def remember(context, collection, obj):
    context.created.append((collection, obj["id"]))
    if obj.get("title"):
        context.objects[obj["title"]] = (collection, obj["id"])


def object_id(context, collection, title):
    """Id of an object this scenario set up, looked up by its title."""
    assert title in context.objects, f'No {SINGULAR[collection]} titled "{title}" was set up'
    stored_collection, stored_id = context.objects[title]
    assert stored_collection == collection, f'"{title}" is a {SINGULAR[stored_collection]}'
    return stored_id


def fetch(collection, object_id):
    """The object behind /collection/:id, or None if it does not exist."""
    response = call("GET", f"/{collection}/{object_id}")
    if response.status_code == 404:
        return None
    assert response.status_code == 200, response.text
    return items(response, collection)[0]


def missing_id(collection):
    """An id guaranteed not to exist: create an object, then delete it."""
    response = call("POST", f"/{collection}", {"title": "temporary"})
    assert response.status_code == 201, response.text
    object_id = response.json()["id"]
    assert call("DELETE", f"/{collection}/{object_id}").status_code == 200
    return object_id
