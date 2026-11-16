@projects @story11
Feature: Create a project
  As a user I want to create a project 
  to get my todos grouped under a single objective.

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

  # BUG-09: active and completed are sent as booleans but come back as the strings "true" / "false".
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
    And the error message "<message>" is returned
    And the number of projects is unchanged

    Examples:
      | field     | value | message                                                            |
      | priority  | high  | Could not find field: priority                                     |
      | completed | yes   | Failed Validation: completed should be BOOLEAN                     |
      | active    | maybe | Failed Validation: active should be BOOLEAN                        |
      | id        | 99    | Invalid Creation: Failed Validation: Not allowed to create with id |
