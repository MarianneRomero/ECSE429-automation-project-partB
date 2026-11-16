@categories @story8
Feature: Update a category
  As a user I want to update a category’s title and description 
  to keep it up to date with the work it groups.

  Background:
    Given the Todo Manager API is running
    And the following categories exist
      | title   | description         |
      | ECSE429 | Software Validation |

  @normal
  Scenario Outline: Amend a single field of a category and keep the other fields
    When I amend the category "ECSE429" with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 200
    And the category "ECSE429" has <field> "<value>"
    And the category "ECSE429" keeps its other fields unchanged

    Examples:
      | field       | value          |
      | description | Testing course |
      | title       | ECSE429 Fall   |

  # BUG-04: PUT /categories/:id is documented as "amend", but it replaces the category:
  # every field left out of the body goes back to its default value.
  @alternate
  Scenario Outline: Replace a category and reset the fields that were left out
    When I replace the category "ECSE429" with the fields
      | field | value   |
      | title | <title> |
    Then the response status code is 200
    And the category "<title>" has title "<title>"
    And the category "<title>" has description ""

    Examples:
      | title      |
      | ECSE429    |
      | Validation |

  # BUG-04: a replace without a title is rejected even though PUT is documented as "amend".
  @error
  Scenario Outline: Update a category with invalid data
    When I <operation> the category "ECSE429" with the fields
      | field   | value   |
      | <field> | <value> |
    Then the response status code is 400
    And the error message "<message>" is returned
    And the category "ECSE429" is unchanged

    Examples:
      | operation | field       | value    | message                                     |
      | replace   | description | No title | title : field is mandatory                  |
      | replace   | title       |          | Failed Validation: title : can not be empty |
      | amend     | title       |          | Failed Validation: title : can not be empty |
      | amend     | colour      | red      | Could not find field: colour                |

  # BUG-08: amend (POST) and replace (PUT) give different "not found" messages for the same missing id;
  # the PUT message ("Invalid GUID") wrongly suggests the id format is invalid.
  @error
  Scenario Outline: Update a category that does not exist
    When I <operation> the category with id "<id>" with the fields
      | field | value     |
      | title | New title |
    Then the response status code is 404
    And the error message "<message>" is returned
    And the number of categories is unchanged

    Examples:
      | operation | id     | message                                                       |
      | amend     | 999999 | No such category entity instance with GUID or ID 999999 found |
      | amend     | abc    | No such category entity instance with GUID or ID abc found    |
      | replace   | 999999 | Invalid GUID for 999999 entity category                       |
      | replace   | abc    | Invalid GUID for abc entity category                          |
