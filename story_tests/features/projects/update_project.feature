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
