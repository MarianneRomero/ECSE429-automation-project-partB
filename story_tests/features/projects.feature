@projects @story11
Feature: Create a project
  As a user I want to create a project so that I can group my work under a single objective.

  Background:
    Given the Todo Manager API is running
    And no project titled "Part B - Report" exists

  @normal
  Scenario Outline: Create a project with only a title and receive a generated id and default values
    When I create a project with title "<title>"
    Then the response status code is 201
    And the response contains the location of the new project
    And the project "<title>" has a generated id
    And the project "<title>" has title "<title>"
    And the project "<title>" has description ""
    And the project "<title>" has active "false"
    And the project "<title>" has completed "false"

    Examples:
      | title           |
      | Part B - Report |
      | Part B - Video  |

  @alternate
  Scenario Outline: Create a project with a description and the optional status fields in JSON or XML
    When I create a project in "<format>" with the fields
      | field       | value         |
      | title       | <title>       |
      | description | <description> |
      | active      | <active>      |
      | completed   | <completed>   |
    Then the response status code is 201
    And the project "<title>" has a generated id
    And the project "<title>" has description "<description>"
    And the project "<title>" has active "<active>"
    And the project "<title>" has completed "<completed>"
    And the project "<title>" appears in the list of all projects

    Examples:
      | format | title                 | description               | active | completed |
      | JSON   | Part B - Report       | Write the final report    | true   | false     |
      | XML    | Part B - Report       | Write the final report    | true   | false     |
      | JSON   | Archived Part A       | Finished in October       | false  | true      |
      | JSON   | Café & Co. (2026)     | Special characters: <>&"' | true   | true      |

  @error
  Scenario Outline: Create a project with invalid data
    When I create a project with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 400
    And the error message contains "<message>"
    And the number of projects is unchanged

    Examples:
      | field       | value         | message                                     |
      | description | Team planning | title : field is mandatory                  |
      | title       |               | Failed Validation: title : can not be empty |
      | active      | maybe         | active                                      | 
      | id          | 99            | id                                          |



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



@projects @story13
Feature: Update a project
  As a user I want to amend or replace a project so that its description and status stay accurate as my work evolves.

  Background:
    Given the Todo Manager API is running
    And the following projects exist
      | title          | description | active | completed |
      | ECSE429 Part B | Story tests | true   | false     |

  @normal
  Scenario Outline: Amend a single field of a project and keep the other fields
    When I amend the project "ECSE429 Part B" with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 200
    And the project "ECSE429 Part B" has <field> "<value>"
    And the project "ECSE429 Part B" keeps its other fields unchanged

    Examples:
      | field       | value             |
      | description | Gherkin scenarios |
      | completed   | true              |
      | active      | false             |

  @alternate
  Scenario Outline: Replace a project and reset the fields that were left out
    When I replace the project "ECSE429 Part B" with the fields
      | field | value   |
      | title | <title> |
    Then the response status code is 200
    And the project "<title>" has title "<title>"
    And the project "<title>" has description ""
    And the project "<title>" has active "false"
    And the project "<title>" has completed "false"

    Examples:
      | title          |
      | ECSE429 Part B |
      | Renamed Part B |

  @error
  Scenario Outline: Update a project with invalid data
    When I <operation> the project "ECSE429 Part B" with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 400
    And the error message contains "<message>"
    And the project "ECSE429 Part B" is unchanged

    Examples:
      | operation | field       | value   | message                                     |
      | replace   | description | Only me | title : field is mandatory                  |
      | replace   | title       |         | Failed Validation: title : can not be empty |
      | amend     | completed   | done    | completed                                   |
      | amend     | active      | 1234    | active                                      |



@projects @story14
Feature: Add todos to a project
  As a user I want to link todos to a project so that all the work belonging to that project is tracked in one place.

  Background:
    Given the Todo Manager API is running
    And a project titled "ECSE429 Project" exists
    And a project titled "ECSE429 Other Project" exists
    And the project "ECSE429 Project" has no todos

  @normal
  Scenario Outline: Add an existing todo to a project
    Given a todo titled "<todo>" exists
    When I add the todo "<todo>" to the project "ECSE429 Project"
    Then the response status code is 201
    And the project "ECSE429 Project" includes the todo "<todo>"
    And the todo "<todo>" is a task of the project "ECSE429 Project"

    Examples:
      | todo            |
      | Write report    |
      | Submit proposal |

  @alternate
  Scenario Outline: Add a todo that already belongs to another project
    Given a todo titled "<todo>" exists
    And the todo "<todo>" is added to the project "ECSE429 Other Project"
    When I add the todo "<todo>" to the project "ECSE429 Project"
    Then the response status code is 201
    And the project "ECSE429 Project" includes the todo "<todo>"
    And the project "ECSE429 Other Project" includes the todo "<todo>"
    And the todo "<todo>" is a task of 2 projects

    Examples:
      | todo         |
      | Shared setup |
      | Final demo   |

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