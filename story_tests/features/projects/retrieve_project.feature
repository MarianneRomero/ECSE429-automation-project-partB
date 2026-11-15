@projects @story12
Feature: Retrieve projects
  As a user I want to retrieve one project or a filtered list of projects so that I can review their details and status.

  Background:
    Given the Todo Manager API is running
    And the following projects exist
      | title          | description    | active | completed |
      | ECSE429 Part A | Exploratory    | false  | true      |
      | ECSE429 Part B | Story tests    | true   | false     |
      | ECSE429 Part C | Non-functional | true   | false     |

  @normal
  Scenario Outline: Fetch an existing project by its id
    When I fetch the project "<project>"
    Then the response status code is 200
    And the project "<project>" has title "<project>"
    And the project "<project>" has description "<description>"
    And the project "<project>" has active "<active>"
    And the project "<project>" has completed "<completed>"

    Examples:
      | project        | description    | active | completed |
      | ECSE429 Part A | Exploratory    | false  | true      |
      | ECSE429 Part B | Story tests    | true   | false     |
      | ECSE429 Part C | Non-functional | true   | false     |

  @alternate
  Scenario Outline: Filter the list of projects with a query parameter
    When I list the projects filtered by "<field>" equal to "<value>"
    Then the response status code is 200
    And the list contains exactly <count> projects
    And every project in the list has "<field>" equal to "<value>"

    Examples:
      | field     | value          | count |
      | title     | ECSE429 Part B | 1     |
      | active    | true           | 2     |
      | completed | true           | 1     |
      | title     | No such title  | 0     |

  @error
  Scenario Outline: Fetch a project that does not exist
    When I fetch the project with id "<project_id>"
    Then the response status code is 404
    And the error message contains "<message>"

    Examples:
      | project_id | message                                            |
      | 999999     | Could not find an instance with projects/999999    |
      | 123456789  | Could not find an instance with projects/123456789 |
      | 0          | Could not find an instance with projects/0         |
