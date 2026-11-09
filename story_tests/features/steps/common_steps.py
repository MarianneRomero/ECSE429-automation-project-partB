"""Steps shared by every feature: set-up, generic creation and response checks."""

from behave import given, then

from story_helpers import create, fetch, field_value, object_id
from api import SINGULAR, not_ready_reason


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


@then('the {collection:Resource} "{title}" has {field} "{value:Text}"')
def step_object_field(context, collection, title, field, value):
    obj = fetch(collection, object_id(context, collection, title))
    assert obj is not None, f'{SINGULAR[collection]} "{title}" no longer exists'
    assert obj.get(field) == value, f"{field} is {obj.get(field)!r}, expected {value!r}"
