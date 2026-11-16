@todos @story1
Feature: Create a todo
  As a user I want to create a todo with a title, a description and a done status to keep 
  track of my tasks.

  Background:
    Given the Todo Manager API is running
    And no todo titled "Lab report" exists
    And no todo titled "Buy groceries" exists

  # BUG-09: doneStatus is sent as a boolean but comes back as the string "true" / "false".
  @normal
  Scenario Outline: Create a todo with a title, a description and a done status
    When I create a todo with the fields
      | field       | value         |
      | title       | <title>       |
      | description | <description> |
      | doneStatus  | <doneStatus>  |
    Then the response status code is 201
    And the todo "<title>" has description "<description>"
    And the todo "<title>" has doneStatus "<doneStatus>"
    And the todo "<title>" appears in the list of all todos

    Examples:
      | title         | description              | doneStatus |
      | Lab report    | Due Friday before 17:00  | false      |
      | Buy groceries | Milk, eggs & bread       | true       |

  @alternate
  Scenario Outline: Create a todo with only a title, in JSON or XML, and get the default values
    When I create a todo in "<format>" with the fields
      | field | value   |
      | title | <title> |
    Then the response status code is 201
    And the todo "<title>" has description ""
    And the todo "<title>" has doneStatus "false"

    Examples:
      | format | title         |
      | JSON   | Lab report    |
      | XML    | Lab report    |
      | XML    | Buy groceries |

  @error
  Scenario Outline: Create a todo with an invalid field
    When I create a todo with the fields
      | field   | value   |
      | title   | <title> |
      | <field> | <value> |
    Then the response status code is 400
    And the error message "<message>" is returned
    And the number of todos is unchanged

    Examples:
      | title      | field       | value       | message                                                            |
      |            | description | Empty title | Failed Validation: title : can not be empty                        |
      | Lab report | doneStatus  | maybe       | Failed Validation: doneStatus should be BOOLEAN                    |
      | Lab report | id          | 99          | Invalid Creation: Failed Validation: Not allowed to create with id |

  @error
  Scenario Outline: Create a todo without a title
    When I create a todo with the fields
      | field       | value         |
      | description | <description> |
    Then the response status code is 400
    And the error message "title : field is mandatory" is returned
    And the number of todos is unchanged

    Examples:
      | description         |
      | Forgot the title    |
      | Another description |
