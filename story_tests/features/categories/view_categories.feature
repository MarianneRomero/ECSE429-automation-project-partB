@categories @story7
Feature: View categories
  As a user I want to look up a category or list only the categories that match a filter to get a quick view of how my work is organized.

  Background:
    Given the Todo Manager API is running
    And the following categories exist
      | title         | description            |
      | ECSE429       | Software Validation    |
      | ECSE321       | Software Engineering   |
      | High Priority | Due before the weekend |

  @normal
  Scenario Outline: Fetch a category by its id
    When I fetch the category "<title>"
    Then the response status code is 200
    And the returned category has title "<title>"
    And the returned category has description "<description>"

    Examples:
      | title         | description            |
      | ECSE429       | Software Validation    |
      | ECSE321       | Software Engineering   |
      | High Priority | Due before the weekend |

  @alternate
  Scenario Outline: List only the categories that match a filter
    When I list the categories filtered by "<field>" equal to "<value>"
    Then the response status code is 200
    And the list contains exactly <count> categories
    And every category in the list has "<field>" equal to "<value>"

    Examples:
      | field       | value                | count |
      | title       | ECSE429              | 1     |
      | description | Software Engineering | 1     |
      | title       | No such title        | 0     |

  @error
  Scenario Outline: Fetch a category that does not exist
    When I fetch the category with id "<id>"
    Then the response status code is 404
    And the error message "Could not find an instance with categories/<id>" is returned

    Examples:
      | id     |
      | 999999 |
      | 0      |
      | abc    |
