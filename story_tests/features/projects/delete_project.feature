@projects @story15
Feature: Delete a project
  As a user I want to delete a project to get a system free of obsolete workstreams.

  Background:
    Given the Todo Manager API is running
    And a project titled "ECSE429 Obsolete" exists
    And a project titled "ECSE429 Keeper" exists

  @normal
  Scenario Outline: Delete an existing project
    Given a project titled "<project>" exists
    When I delete the project "<project>"
    Then the response status code is 200
    And the project "<project>" does not exist
    And the project "ECSE429 Keeper" still exists

    Examples:
      | project          |
      | ECSE429 Obsolete |
      | ECSE429 Part A   |

  @alternate
  Scenario Outline: Delete a project that has todos and keep those todos
    Given the following todos exist
      | title   |
      | <todo1> |
      | <todo2> |
    And the todo "<todo1>" is in the project "ECSE429 Obsolete"
    And the todo "<todo2>" is in the project "ECSE429 Obsolete"
    When I delete the project "ECSE429 Obsolete"
    Then the response status code is 200
    And the project "ECSE429 Obsolete" does not exist
    And the todo "<todo1>" still exists
    And the todo "<todo2>" still exists

    Examples:
      | todo1        | todo2        |
      | Write report | Record video |
      | Old task     | Another task |

  # BUG-08: DELETE gives a different "not found" message than GET, POST and PUT.
  @error
  Scenario Outline: Delete a project that does not exist
    When I delete the project with id "<id>"
    Then the response status code is 404
    And the error message "Could not find any instances with projects/<id>" is returned
    And the number of projects is unchanged

    Examples:
      | id     |
      | 999999 |
      | abc    |
      | -1     |
