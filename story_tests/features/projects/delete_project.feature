@projects @story15
Feature: Delete a project
  As a user I want to delete a project so that I can remove obsolete workstreams from the system.

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
    And the todo "<todo1>" is added to the project "ECSE429 Obsolete"
    And the todo "<todo2>" is added to the project "ECSE429 Obsolete"
    When I delete the project "ECSE429 Obsolete"
    Then the response status code is 200
    And the project "ECSE429 Obsolete" does not exist
    And the todo "<todo1>" still exists
    And the todo "<todo2>" still exists

    Examples:
      | todo1        | todo2        |
      | Write report | Record video |
      | Old task     | Another task |

  @error
  Scenario Outline: Delete a project that does not exist
    When I delete the project with id "<project_id>"
    Then the response status code is 404
    And the error message contains "<message>"
    And the number of projects is unchanged

    Examples:
      | project_id | message                                              |
      | 999999     | Could not find any instances with projects/999999    |
      | 123456789  | Could not find any instances with projects/123456789 |
