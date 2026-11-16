@todos @story2
Feature: View todos
  As a user I want to retrieve one todo or a filtered list of todos 
  to get a quick view of what is done and what is left to do.

  Background:
    Given the Todo Manager API is running
    And the following todos exist
      | title             | description         | doneStatus |
      | Read chapter 4    | Software testing    | false      |
      | Submit assignment | Upload to myCourses | true       |
      | Study for quiz    | Chapters 1 to 3     | false      |

  # BUG-05: GET /todos/:id returns the todo inside a one-element "todos" list, not a bare todo.
  @normal
  Scenario Outline: Fetch a todo by its id
    When I fetch the todo "<title>"
    Then the response status code is 200
    And the returned todo has title "<title>"
    And the returned todo has description "<description>"
    And the returned todo has doneStatus "<doneStatus>"

    Examples:
      | title             | description         | doneStatus |
      | Read chapter 4    | Software testing    | false      |
      | Submit assignment | Upload to myCourses | true       |

  @alternate
  Scenario Outline: List only the todos that match a filter
    When I list the todos filtered by "<field>" equal to "<value>"
    Then the response status code is 200
    And every todo in the list has "<field>" equal to "<value>"
    And the list includes the todo "<included>"
    And the list does not include the todo "<excluded>"

    Examples:
      | field      | value             | included          | excluded          |
      | doneStatus | true              | Submit assignment | Read chapter 4    |
      | doneStatus | false             | Study for quiz    | Submit assignment |
      | title      | Read chapter 4    | Read chapter 4    | Study for quiz    |

  # BUG-08: GET gives a different "not found" message than POST, PUT and DELETE.
  @error
  Scenario Outline: Fetch a todo that does not exist
    When I fetch the todo with id "<id>"
    Then the response status code is 404
    And the error message "Could not find an instance with todos/<id>" is returned

    Examples:
      | id     |
      | 999999 |
      | abc    |
