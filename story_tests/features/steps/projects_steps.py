"""Steps for projects.feature."""

from behave import then, when

from story_helpers import fetch, missing_id, object_id, remember
from api import call, link, related_ids


@when('I add the todo "{todo}" to the project "{project}"')
def step_add_todo_to_project(context, todo, project):
    project_id = object_id(context, "projects", project)
    context.response = link("projects", project_id, "tasks", object_id(context, "todos", todo))


@when('I add a new todo titled "{title}" to the project "{project}"')
def step_add_new_todo_to_project(context, title, project):
    project_id = object_id(context, "projects", project)
    context.response = call("POST", f"/projects/{project_id}/tasks", {"title": title})
    if context.response.status_code == 201:
        remember(context, "todos", context.response.json())


@when('I add the todo "{todo}" to a project that does not exist')
def step_add_todo_to_missing_project(context, todo):
    context.response = link("projects", missing_id("projects"), "tasks", object_id(context, "todos", todo))


@then('the project "{project}" includes the todo "{todo}"')
def step_project_includes_todo(context, project, todo):
    obj = fetch("projects", object_id(context, "projects", project))
    assert object_id(context, "todos", todo) in related_ids(obj, "tasks"), obj


@then('the todo "{todo}" is a task of the project "{project}"')
def step_todo_task_of_project(context, todo, project):
    obj = fetch("todos", object_id(context, "todos", todo))
    assert object_id(context, "projects", project) in related_ids(obj, "tasksof"), obj
