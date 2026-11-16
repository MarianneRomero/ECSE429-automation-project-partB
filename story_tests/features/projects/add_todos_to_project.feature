@projects @story14
Feature: Add todos to a project
  As a user I want to link todos to a project to get all the work belonging to that project tracked in one place.

  Background:
    Given the Todo Manager API is running
    And a project titled "ECSE429 Project" exists
    And a project titled "ECSE429 Other Project" exists
    And the project "ECSE429 Project" has no related todo

  @normal
  Scenario Outline: Add an existing todo to a project
    Given a todo titled "<todo>" exists
    When I add the todo "<todo>" to the project "ECSE429 Project"
    Then the response status code is 201
    And the project "ECSE429 Project" includes the todo "<todo>"
    And the todo "<todo>" is in the project "ECSE429 Project"

    Examples:
      | todo            |
      | Write report    |
      | Submit proposal |

  @alternate
  Scenario Outline: Add a todo that already belongs to another project
    Given a todo titled "<todo>" exists
    And the todo "<todo>" is in the project "ECSE429 Other Project"
    When I add the todo "<todo>" to the project "ECSE429 Project"
    Then the response status code is 201
    And the project "ECSE429 Project" includes the todo "<todo>"
    And the project "ECSE429 Other Project" includes the todo "<todo>"
    And the todo "<todo>" is in 2 projects

    Examples:
      | todo         |
      | Shared setup |
      | Final demo   |

  # BUG-03: the API returns 404, but Swagger only documents 201 and 400.
  @error
  Scenario Outline: Add a todo to a project that does not exist
    Given a todo titled "<todo>" exists
    When I add the todo "<todo>" to a project that does not exist
    Then the response status code is 404
    And the error message contains "<message>"

    Examples:
      | todo         | message                                      |
      | Write report | Could not find parent thing for relationship |
      | Submit task  | Could not find parent thing for relationship |
