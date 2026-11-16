@categories @story6
Feature: Create a category
  As a user I want to create a category 
  to group related todos and projects.
  
  Background:
    Given the Todo Manager API is running
    And no category titled "ECSE429" exists
    And no category titled "High Priority" exists

  @normal
  Scenario Outline: Create a category with only a title and receive a generated id and default values
    When I create a category with title "<title>"
    Then the response status code is 201
    And the response contains the location of the new category
    And the category "<title>" has a generated id
    And the category "<title>" has title "<title>"
    And the category "<title>" has description ""
    And the category "<title>" appears in the list of all categories

    Examples:
      | title         |
      | ECSE429       |
      | High Priority |

  @alternate
  Scenario Outline: Create a category with a description in JSON or XML
    When I create a category in "<format>" with the fields
      | field       | value         |
      | title       | <title>       |
      | description | <description> |
    Then the response status code is 201
    And the category "<title>" has a generated id
    And the category "<title>" has description "<description>"
    And the category "<title>" appears in the list of all categories

    Examples:
      | format | title             | description               |
      | JSON   | ECSE429           | Software Validation       |
      | XML    | ECSE429           | Software Validation       |
      | XML    | High Priority     | Due before the weekend    |
      | JSON   | Café & Co. (2026) | Special characters: <>&"' |

  @error
  Scenario Outline: Create a category with an invalid field
    When I create a category with the fields
      | field   | value   |
      | title   | <title> |
      | <field> | <value> |
    Then the response status code is 400
    And the error message "<message>" is returned
    And the number of categories is unchanged

    Examples:
      | title   | field       | value       | message                                                            |
      |         | description | Empty title | Failed Validation: title : can not be empty                        |
      | ECSE429 | colour      | red         | Could not find field: colour                                       |
      | ECSE429 | id          | 99          | Invalid Creation: Failed Validation: Not allowed to create with id |

  @error
  Scenario Outline: Create a category without a title
    When I create a category with the fields
      | field       | value         |
      | description | <description> |
    Then the response status code is 400
    And the error message "title : field is mandatory" is returned
    And the number of categories is unchanged

    Examples:
      | description         |
      | Forgot the title    |
      | Another description |
