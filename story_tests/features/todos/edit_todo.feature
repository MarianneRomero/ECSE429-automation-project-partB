@todos @story4
Feature: Edit a todo
  As a student, I want to change the title and description of a todo,
  so that my todo list stays accurate when my plans change.

  Background:
    Given the Todo Manager API is running
    And the following todos exist
      | title        | description | doneStatus |
      | Draft report | First draft | true       |

  @normal
  Scenario Outline: Amend the title and description of a todo and keep its done status
    When I amend the todo "Draft report" with the fields
      | field       | value         |
      | title       | <title>       |
      | description | <description> |
    Then the response status code is 200
    And the todo "<title>" has description "<description>"
    And the todo "<title>" keeps its other fields unchanged

    Examples:
      | title        | description           |
      | Final report | Ready to submit       |
      | Draft report | Second draft, revised |

  # BUG-04: PUT /todos/:id is documented as "amend", but it replaces the todo:
  # every field left out of the body goes back to its default value.
  @alternate
  Scenario Outline: Replace a todo and reset the fields that were left out
    When I replace the todo "Draft report" with the fields
      | field | value   |
      | title | <title> |
    Then the response status code is 200
    And the todo "<title>" has description ""
    And the todo "<title>" has doneStatus "false"

    Examples:
      | title         |
      | Draft report  |
      | Outline ideas |

  # BUG-04: a replace without a title is rejected even though PUT is documented as "amend".
  @error
  Scenario Outline: Edit a todo with invalid data
    When I <operation> the todo "Draft report" with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 400
    And the error message "<message>" is returned
    And the todo "Draft report" is unchanged

    Examples:
      | operation | field       | value     | message                                         |
      | amend     | title       |           | Failed Validation: title : can not be empty     |
      | amend     | doneStatus  | finished  | Failed Validation: doneStatus should be BOOLEAN |
      | replace   | description | No title  | title : field is mandatory                      |
