@categories
Feature: Create a category
  As a student, I want to create categories for my todos and projects,
  so that I can group my work by course or priority.

  Background:
    Given the Todo Manager API is running

  # Normal flow
  @normal
  Scenario Outline: Create a category with a title and a description
    When I create a category with title "<title>" and description "<description>"
    Then the response status code is 201
    And the category "<title>" has description "<description>"

    Examples:
      | title         | description              |
      | ECSE429       | Software Validation      |
      | High Priority | Due before the weekend   |

  # Alternate flow
  @alternate
  Scenario: Create a category with only a title
    When I create a category with title "Low Priority"
    Then the response status code is 201
    And the category "Low Priority" has description ""

  # Error flow
  @error
  Scenario Outline: Create a category with a missing or empty title
    When I create a category with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 400
    And the error message "<message>" is returned

    Examples:
      | field       | value        | message                                   |
      | description | No title     | title : field is mandatory                |
      | title       |              | Failed Validation: title : can not be empty |
