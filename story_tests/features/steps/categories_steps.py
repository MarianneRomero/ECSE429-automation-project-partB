"""Steps for categories.feature."""

from behave import when

from story_helpers import create


@when('I create a category with title "{title}" and description "{description}"')
def step_create_category_with_description(context, title, description):
    context.response = create(context, "categories", {"title": title, "description": description})


@when('I create a category with title "{title}"')
def step_create_category(context, title):
    context.response = create(context, "categories", {"title": title})


@when("I create a category with the fields")
def step_create_category_with_fields(context):
    """Table rows are | field | value |."""
    fields = {row["field"]: row["value"] for row in context.table}
    context.response = create(context, "categories", fields)
