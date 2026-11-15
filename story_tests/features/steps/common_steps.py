"""Steps shared by every feature: set-up, generic CRUD actions and response checks."""

import xml.etree.ElementTree as ElementTree
from urllib.parse import urlencode

import parse
import requests
from behave import given, register_type, then, when
from behave.api.pending_step import StepNotImplementedError

from story_helpers import create, fetch, field_value, object_id, remember
from api import BASE_URL, SINGULAR, TIMEOUT, call, items, not_ready_reason, snapshot


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


def _object_before_action(context, collection, title):
    return context.state_before[collection][object_id(context, collection, title)]


def _object_now(context, collection, title):
    return snapshot()[collection][object_id(context, collection, title)]


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
    raise StepNotImplementedError


@given('the {child:Resource} "{child_title:Text}" is in the {parent:Resource} "{parent_title:Text}"')
def step_child_linked_to_parent(context, child, child_title, parent, parent_title):
    raise StepNotImplementedError


@when('I create a {collection:Resource} with title "{title:Text}"')
def step_create_with_title(context, collection, title):
    raise StepNotImplementedError


@when("I create a {collection:Resource} with the fields")
def step_create_with_fields(context, collection):
    raise StepNotImplementedError


@when('I create a {collection:Resource} in "{body_format}" with the fields')
def step_create_in_format(context, collection, body_format):
    raise StepNotImplementedError


@when('I fetch the {collection:Resource} "{title:Text}"')
def step_fetch(context, collection, title):
    raise StepNotImplementedError


@when('I fetch the {collection:Resource} with id "{raw_id}"')
def step_fetch_by_id(context, collection, raw_id):
    raise StepNotImplementedError


@when("I list all {collection:Collection}")
def step_list_all(context, collection):
    raise StepNotImplementedError


@when('I list the {collection:Collection} filtered by "{field}" equal to "{value:Text}"')
def step_list_filtered(context, collection, field, value):
    raise StepNotImplementedError


@when('I amend the {collection:Resource} "{title:Text}" with the fields')
def step_amend(context, collection, title):
    raise StepNotImplementedError


@when('I replace the {collection:Resource} "{title:Text}" with the fields')
def step_replace(context, collection, title):
    raise StepNotImplementedError


@when('I amend the {collection:Resource} with id "{raw_id}" with the fields')
def step_amend_by_id(context, collection, raw_id):
    raise StepNotImplementedError


@when('I replace the {collection:Resource} with id "{raw_id}" with the fields')
def step_replace_by_id(context, collection, raw_id):
    raise StepNotImplementedError


@when('I delete the {collection:Resource} "{title:Text}"')
def step_delete(context, collection, title):
    raise StepNotImplementedError


@when('I delete the {collection:Resource} with id "{raw_id}"')
def step_delete_by_id(context, collection, raw_id):
    raise StepNotImplementedError


@when('I add the {child:Resource} "{child_title:Text}" to the {parent:Resource} "{parent_title:Text}"')
def step_add_child_to_parent(context, child, child_title, parent, parent_title):
    raise StepNotImplementedError


@when('I add the {child:Resource} "{child_title:Text}" to a {parent:Resource} that does not exist')
def step_add_child_to_missing_parent(context, child, child_title, parent):
    raise StepNotImplementedError


@when('I add a {child:Resource} that does not exist to the {parent:Resource} "{parent_title:Text}"')
def step_add_missing_child_to_parent(context, child, parent, parent_title):
    raise StepNotImplementedError


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
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" has a generated id')
def step_generated_id(context, collection, title):
    raise StepNotImplementedError


@then('the returned {collection:Resource} has {field} "{value:AnyText}"')
def step_returned_field(context, collection, field, value):
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" appears in the list of all {listed:Collection}')
def step_appears_in_list_of_all(context, collection, title, listed):
    raise StepNotImplementedError


@then("the list contains exactly {count:d} {collection:Collection}")
def step_list_count(context, count, collection):
    raise StepNotImplementedError


@then('every {collection:Resource} in the list has "{field}" equal to "{value:Text}"')
def step_every_listed_has(context, collection, field, value):
    raise StepNotImplementedError


@then('the list includes the {collection:Resource} "{title:Text}"')
def step_list_includes(context, collection, title):
    raise StepNotImplementedError


@then('the list does not include the {collection:Resource} "{title:Text}"')
def step_list_excludes(context, collection, title):
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" does not exist')
def step_does_not_exist(context, collection, title):
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" still exists')
def step_still_exists(context, collection, title):
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" is unchanged')
def step_unchanged(context, collection, title):
    raise StepNotImplementedError


@then('the {collection:Resource} "{title:Text}" keeps its other fields unchanged')
def step_other_fields_unchanged(context, collection, title):
    raise StepNotImplementedError


@then("the number of {collection:Collection} is unchanged")
def step_count_unchanged(context, collection):
    raise StepNotImplementedError


@then('the {parent:Resource} "{parent_title:Text}" includes the {child:Resource} "{child_title:Text}"')
def step_parent_includes_child(context, parent, parent_title, child, child_title):
    raise StepNotImplementedError


@then('the {parent:Resource} "{parent_title:Text}" does not include the {child:Resource} "{child_title:Text}"')
def step_parent_excludes_child(context, parent, parent_title, child, child_title):
    raise StepNotImplementedError


@given('the {parent:Resource} "{parent_title:Text}" has no related {child:Resource}')
@then('the {parent:Resource} "{parent_title:Text}" has no related {child:Resource}')
def step_parent_has_no_children(context, parent, parent_title, child):
    raise StepNotImplementedError


@then('the {child:Resource} "{child_title:Text}" is in the {parent:Resource} "{parent_title:Text}"')
def step_child_in_parent(context, child, child_title, parent, parent_title):
    raise StepNotImplementedError


@then('the {child:Resource} "{child_title:Text}" is in {count:d} {parents:Collection}')
def step_child_in_parent_count(context, child, child_title, count, parents):
    raise StepNotImplementedError
