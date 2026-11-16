@projects @story12
Feature: Retrieve projects
  As a user I want to retrieve one project or a filtered list of projects to get an overview of their details and status.

  Background:
    Given the Todo Manager API is running
    And the following projects exist
      | title          | description    | active | completed |
      | ECSE429 Part A | Exploratory    | false  | true      |
      | ECSE429 Part B | Story tests    | true   | false     |
      | ECSE429 Part C | Non-functional | true   | false     |

  # BUG-05: GET /projects/:id returns the project inside a one-element "projects" list, not a bare project.
  @normal
  Scenario Outline: Fetch an existing project by its id
    When I fetch the project "<project>"
    Then the response status code is 200
    And the returned project has title "<project>"
    And the returned project has description "<description>"
    And the returned project has active "<active>"
    And the returned project has completed "<completed>"

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

  # BUG-08: GET gives a different "not found" message than POST, PUT and DELETE.
  @error
  Scenario Outline: Fetch a project that does not exist
    When I fetch the project with id "<id>"
    Then the response status code is 404
    And the error message "Could not find an instance with projects/<id>" is returned

    Examples:
      | id     |
      | 999999 |
      | 0      |
      | abc    |
      | -1     |
