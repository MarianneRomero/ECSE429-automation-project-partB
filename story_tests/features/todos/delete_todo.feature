@todos @story5
Feature: Delete a todo
  As a student, I want to delete a todo I no longer need.

  Background:
    Given the Todo Manager API is running
    And the following todos exist
      | title          |
      | Old reminder   |
      | Cancelled lab  |
      | Keep this todo |
    And a project titled "ECSE429" exists
    And a category titled "School" exists

  @normal
  Scenario Outline: Delete a todo and keep the other todos
    When I delete the todo "<title>"
    Then the response status code is 200
    And the todo "<title>" does not exist
    And the todo "Keep this todo" still exists

    Examples:
      | title         |
      | Old reminder  |
      | Cancelled lab |

  @alternate
  Scenario Outline: Delete a todo that belongs to a project and a category
    Given the todo "<title>" is in the project "ECSE429"
    And the todo "<title>" is in the category "School"
    When I delete the todo "<title>"
    Then the response status code is 200
    And the todo "<title>" does not exist
    And the project "ECSE429" does not include the todo "<title>"
    And the project "ECSE429" still exists
    And the category "School" still exists

    Examples:
      | title         |
      | Old reminder  |
      | Cancelled lab |

  @error
  Scenario Outline: Delete a todo that was already deleted
    Given the todo "<title>" was already deleted
    When I delete the todo "<title>"
    Then the response status code is 404
    And the error message contains "Could not find any instances with todos/"
    And the number of todos is unchanged

    Examples:
      | title         |
      | Old reminder  |
      | Cancelled lab |

  # BUG-08: DELETE gives a different "not found" message than GET, POST and PUT.
  @error
  Scenario Outline: Delete a todo with an id that does not exist
    When I delete the todo with id "<id>"
    Then the response status code is 404
    And the error message "Could not find any instances with todos/<id>" is returned
    And the number of todos is unchanged

    Examples:
      | id     |
      | 999999 |
      | abc    |
