"""Steps shared by every feature: set-up, generic CRUD actions and response checks."""

import xml.etree.ElementTree as ElementTree
from urllib.parse import urlencode

import parse
import requests
from behave import given, register_type, then, when
from behave.api.pending_step import StepNotImplementedError

from story_helpers import create, fetch, field_value, missing_id, object_id, remember
from api import BASE_URL, SINGULAR, TIMEOUT, call, items, link, not_ready_reason, related_ids, snapshot

# (parent collection, child collection) -> relationship name in /parent/:id/<relationship>
RELATIONSHIPS = {
    ("categories", "todos"): "todos",
    ("categories", "projects"): "projects",
    ("projects", "todos"): "tasks",
    ("projects", "categories"): "categories",
    ("todos", "categories"): "categories",
    ("todos", "projects"): "tasksof",
}


@parse.with_pattern(r".*")
def parse_any_text(text):
    """Quoted text that may contain quotes itself; only use it for the last value of a step."""
    return text


register_type(AnyText=parse_any_text)


def _table_fields(table):
    """A | field | value | table as a request body."""
    return {row["field"]: field_value(row["value"]) for row in table}


def _record_state(context):
    """Keep the server state from just before an action for the "unchanged" checks."""
    context.state_before = snapshot()


def _filtered_list(collection, field, value):
    return call("GET", f"/{collection}?{urlencode({field: value})}")


def _create_xml(context, collection, table):
    root = ElementTree.Element(SINGULAR[collection])
    for row in table:
        ElementTree.SubElement(root, row["field"]).text = row["value"]
    response = requests.post(
        f"{BASE_URL}/{collection}", data=ElementTree.tostring(root, encoding="utf-8"),
        headers={"Accept": "application/json", "Content-Type": "application/xml"}, timeout=TIMEOUT,
    )
    if response.status_code == 201:
        remember(context, collection, response.json())
    return response


def _update(context, method, collection, title):
    """Amend (POST) or replace (PUT) an object with the fields of the step table."""
    _record_state(context)
    context.sent_fields = _table_fields(context.table)
    path = f"/{collection}/{object_id(context, collection, title)}"
    context.response = call(method, path, context.sent_fields)
    if context.response.status_code == 200:
        updated = context.response.json()
        context.objects[updated["title"]] = (collection, updated["id"])


def _update_by_id(context, method, collection, raw_id):
    _record_state(context)
    context.response = call(method, f"/{collection}/{raw_id}", _table_fields(context.table))


def _object_before_action(context, collection, title):
    return context.state_before[collection][object_id(context, collection, title)]


def _object_now(context, collection, title):
    return snapshot()[collection][object_id(context, collection, title)]


def _relationship(parent, child):
    assert (parent, child) in RELATIONSHIPS, f"no relationship from {parent} to {child}"
    return RELATIONSHIPS[(parent, child)]


def _related_children(parent, parent_id, child):
    """Ids of the children listed at /parent/:id/<relationship>."""
    response = call("GET", f"/{parent}/{parent_id}/{_relationship(parent, child)}")
    assert response.status_code == 200, response.text
    return {obj["id"] for obj in items(response, child)}


def _link(context, child, child_id, parent, parent_id):
    context.response = link(parent, parent_id, _relationship(parent, child), child_id)


# ---------------------------------------------------------------- Given

@given("the Todo Manager API is running")
def step_api_running(context):
    reason = not_ready_reason()
    assert reason is None, reason


@given('a {collection:Resource} titled "{title}" exists')
def step_object_exists(context, collection, title):
    response = create(context, collection, {"title": title})
    assert response.status_code == 201, response.text


@given("the following {collection:Collection} exist")
def step_objects_exist(context, collection):
    """Table columns are field names, e.g. | title | doneStatus |."""
    for row in context.table:
        fields = {heading: field_value(row[heading]) for heading in row.headings}
        response = create(context, collection, fields)
        assert response.status_code == 201, response.text


@given('no {collection:Resource} titled "{title:Text}" exists')
def step_no_object_titled(context, collection, title):
    """A precondition check: deleting it here would break the end-of-scenario state check."""
    response = _filtered_list(collection, "title", title)
    assert response.status_code == 200, response.text
    assert items(response, collection) == [], f'a {SINGULAR[collection]} titled "{title}" already exists'


@given('the {collection:Resource} "{title:Text}" was already deleted')
def step_already_deleted(context, collection, title):
    raise StepNotImplementedError


@given('the {child:Resource} "{child_title:Text}" is in the {parent:Resource} "{parent_title:Text}"')
def step_child_linked_to_parent(context, child, child_title, parent, parent_title):
    child_id = object_id(context, child, child_title)
    response = link(parent, object_id(context, parent, parent_title), _relationship(parent, child), child_id)
    assert response.status_code == 201, response.text


# ---------------------------------------------------------------- When

@when('I create a {collection:Resource} with title "{title:Text}"')
def step_create_with_title(context, collection, title):
    _record_state(context)
    context.response = create(context, collection, {"title": title})


@when("I create a {collection:Resource} with the fields")
def step_create_with_fields(context, collection):
    _record_state(context)
    context.response = create(context, collection, _table_fields(context.table))


@when('I create a {collection:Resource} in "{body_format}" with the fields')
def step_create_in_format(context, collection, body_format):
    _record_state(context)
    body_format = body_format.upper()
    if body_format == "XML":
        context.response = _create_xml(context, collection, context.table)
    elif body_format == "JSON":
        context.response = create(context, collection, _table_fields(context.table))
    else:
        raise ValueError(f"Unknown format {body_format!r}; use JSON or XML")


@when('I fetch the {collection:Resource} "{title:Text}"')
def step_fetch(context, collection, title):
    context.response = call("GET", f"/{collection}/{object_id(context, collection, title)}")


@when('I fetch the {collection:Resource} with id "{raw_id}"')
def step_fetch_by_id(context, collection, raw_id):
    context.response = call("GET", f"/{collection}/{raw_id}")


@when('I list the {collection:Collection} filtered by "{field}" equal to "{value:Text}"')
def step_list_filtered(context, collection, field, value):
    context.response = _filtered_list(collection, field, value)


@when('I amend the {collection:Resource} "{title:Text}" with the fields')
def step_amend(context, collection, title):
    _update(context, "POST", collection, title)


@when('I replace the {collection:Resource} "{title:Text}" with the fields')
def step_replace(context, collection, title):
    _update(context, "PUT", collection, title)


@when('I amend the {collection:Resource} with id "{raw_id}" with the fields')
def step_amend_by_id(context, collection, raw_id):
    _update_by_id(context, "POST", collection, raw_id)


@when('I replace the {collection:Resource} with id "{raw_id}" with the fields')
def step_replace_by_id(context, collection, raw_id):
    _update_by_id(context, "PUT", collection, raw_id)


@when('I delete the {collection:Resource} "{title:Text}"')
def step_delete(context, collection, title):
    _record_state(context)
    context.response = call("DELETE", f"/{collection}/{object_id(context, collection, title)}")


@when('I delete the {collection:Resource} with id "{raw_id}"')
def step_delete_by_id(context, collection, raw_id):
    _record_state(context)
    context.response = call("DELETE", f"/{collection}/{raw_id}")


@when('I add the {child:Resource} "{child_title:Text}" to the {parent:Resource} "{parent_title:Text}"')
def step_add_child_to_parent(context, child, child_title, parent, parent_title):
    _link(context, child, object_id(context, child, child_title), parent, object_id(context, parent, parent_title))


@when('I add the {child:Resource} "{child_title:Text}" to a {parent:Resource} that does not exist')
def step_add_child_to_missing_parent(context, child, child_title, parent):
    _link(context, child, object_id(context, child, child_title), parent, missing_id(parent))


@when('I add a {child:Resource} that does not exist to the {parent:Resource} "{parent_title:Text}"')
def step_add_missing_child_to_parent(context, child, parent, parent_title):
    _link(context, child, missing_id(child), parent, object_id(context, parent, parent_title))


# ---------------------------------------------------------------- Then

@then("the response status code is {status:d}")
def step_status_code(context, status):
    assert context.response.status_code == status, (
        f"expected {status}, got {context.response.status_code}: {context.response.text}"
    )


@then('the error message "{message}" is returned')
def step_error_message(context, message):
    errors = context.response.json().get("errorMessages", [])
    assert message in errors, f"{message!r} not in {errors}"


@then('the error message contains "{text}"')
def step_error_message_contains(context, text):
    errors = context.response.json().get("errorMessages", [])
    assert any(text in error for error in errors), f"{text!r} not found in {errors}"


@then('the {collection:Resource} "{title}" has {field} "{value:AnyText}"')
def step_object_field(context, collection, title, field, value):
    obj = fetch(collection, object_id(context, collection, title))
    assert obj is not None, f'{SINGULAR[collection]} "{title}" no longer exists'
    assert obj.get(field) == value, f"{field} is {obj.get(field)!r}, expected {value!r}"


@then("the response contains the location of the new {collection:Resource}")
def step_location_of_new(context, collection):
    new_id = context.response.json()["id"]
    location = context.response.headers.get("Location")
    assert location == f"{collection}/{new_id}", f"Location is {location!r}, expected {collection}/{new_id}"


@then('the {collection:Resource} "{title:Text}" has a generated id')
def step_generated_id(context, collection, title):
    generated = object_id(context, collection, title)
    assert generated.isdigit(), f"id {generated!r} is not a generated number"
    assert context.response.json()["id"] == generated, "the response does not carry the new id"


@then('the returned {collection:Resource} has {field} "{value:AnyText}"')
def step_returned_field(context, collection, field, value):
    returned = items(context.response, collection)
    assert len(returned) == 1, f"expected one {SINGULAR[collection]}, got {len(returned)}"
    assert returned[0].get(field) == value, f"{field} is {returned[0].get(field)!r}, expected {value!r}"


@then('the {collection:Resource} "{title:Text}" appears in the list of all {listed:Collection}')
def step_appears_in_list_of_all(context, collection, title, listed):
    assert collection == listed, f"a {SINGULAR[collection]} is never listed in {listed}"
    wanted = object_id(context, collection, title)
    listed_ids = {obj["id"] for obj in items(call("GET", f"/{collection}"), collection)}
    assert wanted in listed_ids, f'{SINGULAR[collection]} "{title}" is not in the list of all {collection}'


@then("the list contains exactly {count:d} {collection:Collection}")
def step_list_count(context, count, collection):
    listed = items(context.response, collection)
    assert len(listed) == count, f"expected {count} {collection}, got {len(listed)}: {listed}"


@then('every {collection:Resource} in the list has "{field}" equal to "{value:Text}"')
def step_every_listed_has(context, collection, field, value):
    wrong = [obj for obj in items(context.response, collection) if obj.get(field) != value]
    assert not wrong, f"these {collection} do not have {field} {value!r}: {wrong}"


@then('the list includes the {collection:Resource} "{title:Text}"')
def step_list_includes(context, collection, title):
    raise StepNotImplementedError


@then('the list does not include the {collection:Resource} "{title:Text}"')
def step_list_excludes(context, collection, title):
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" does not exist')
def step_does_not_exist(context, collection, title):
    assert fetch(collection, object_id(context, collection, title)) is None, (
        f'{SINGULAR[collection]} "{title}" still exists'
    )


@then('the {collection:Resource} "{title:Text}" still exists')
def step_still_exists(context, collection, title):
    assert fetch(collection, object_id(context, collection, title)) is not None, (
        f'{SINGULAR[collection]} "{title}" no longer exists'
    )


@then('the {collection:Resource} "{title:Text}" is unchanged')
def step_unchanged(context, collection, title):
    before = _object_before_action(context, collection, title)
    now = _object_now(context, collection, title)
    assert now == before, f"{SINGULAR[collection]} changed from {before} to {now}"


@then('the {collection:Resource} "{title:Text}" keeps its other fields unchanged')
def step_other_fields_unchanged(context, collection, title):
    before = _object_before_action(context, collection, title)
    now = _object_now(context, collection, title)
    changed = {
        field: (before.get(field), now.get(field))
        for field in before.keys() | now.keys()
        if field not in context.sent_fields and before.get(field) != now.get(field)
    }
    assert not changed, f"fields that were not sent changed (before, after): {changed}"


@then("the number of {collection:Collection} is unchanged")
def step_count_unchanged(context, collection):
    before = len(context.state_before[collection])
    now = len(snapshot()[collection])
    assert now == before, f"there were {before} {collection} before and {now} after"


@then('the {parent:Resource} "{parent_title:Text}" includes the {child:Resource} "{child_title:Text}"')
def step_parent_includes_child(context, parent, parent_title, child, child_title):
    children = _related_children(parent, object_id(context, parent, parent_title), child)
    assert object_id(context, child, child_title) in children, (
        f'{SINGULAR[parent]} "{parent_title}" does not include the {SINGULAR[child]} "{child_title}"'
    )


@then('the {parent:Resource} "{parent_title:Text}" does not include the {child:Resource} "{child_title:Text}"')
def step_parent_excludes_child(context, parent, parent_title, child, child_title):
    raise StepNotImplementedError


@given('the {parent:Resource} "{parent_title:Text}" has no related {child:Resource}')
@then('the {parent:Resource} "{parent_title:Text}" has no related {child:Resource}')
def step_parent_has_no_children(context, parent, parent_title, child):
    children = _related_children(parent, object_id(context, parent, parent_title), child)
    assert not children, f'{SINGULAR[parent]} "{parent_title}" has related {child}: {sorted(children)}'


@then('the {child:Resource} "{child_title:Text}" is in the {parent:Resource} "{parent_title:Text}"')
def step_child_in_parent(context, child, child_title, parent, parent_title):
    raise StepNotImplementedError


@then('the {child:Resource} "{child_title:Text}" is in {count:d} {parents:Collection}')
def step_child_in_parent_count(context, child, child_title, count, parents):
    raise StepNotImplementedError
