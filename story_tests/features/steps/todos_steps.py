"""Steps for todos.feature."""

from behave import when

from story_helpers import missing_id, object_id
from api import call


@when('I mark the todo "{title}" as done')
def step_mark_done(context, title):
    todo_id = object_id(context, "todos", title)
    context.response = call("POST", f"/todos/{todo_id}", {"doneStatus": True})


@when("I mark a todo that does not exist as done")
def step_mark_missing_done(context):
    context.response = call("POST", f"/todos/{missing_id('todos')}", {"doneStatus": True})


@when('I set the done status of the todo "{title}" to "{value}"')
def step_set_done_status_raw(context, title, value):
    """Sends the value as a JSON string, not a boolean."""
    todo_id = object_id(context, "todos", title)
    context.response = call("POST", f"/todos/{todo_id}", {"doneStatus": value})
