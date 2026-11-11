@categories
Feature: Manage categories
  Each Rule below is one user story for the /categories endpoints.

  Background:
    Given the Todo Manager API is running

  @create
  Rule: Create a category
    As a user I want to create a category to group my todos and projects by course or priority

    # Normal flow
    @normal
    Scenario Outline: Create a category with a title and a description
      When I create a category with title "<title>" and description "<description>"
      Then the response status code is 201
      And the category "<title>" has description "<description>"

      Examples:
        | title         | description            |
        | ECSE429       | Software Validation    |
        | High Priority | Due before the weekend |

    # Alternate flow
    @alternate
    Scenario Outline: Create a category with only a title
      When I create a category with title "<title>"
      Then the response status code is 201
      And the category "<title>" has description ""

      Examples:
        | title        |
        | Low Priority |
        | ECSE321      |

    # Error flow
    @error
    Scenario Outline: Create a category with invalid fields
      When I create a category with the fields
        | field   | value   |
        | <field> | <value> |
      Then the response status code is 400
      And the error message "<message>" is returned

      Examples:
        | field       | value    | message                                                             |
        | description | No title | title : field is mandatory                                          |
        | title       |          | Failed Validation: title : can not be empty                         |
        | id          | 99       | Invalid Creation: Failed Validation: Not allowed to create with id |

  @view
  Rule: View categories
    As a user I want to view my categories to see how my work is organized

    Background:
      Given the following categories exist
        | title         | description            |
        | ECSE429       | Software Validation    |
        | High Priority | Due before the weekend |

    # Normal flow
    @normal
    Scenario Outline: View a specific category
      When I view the category "<title>"
      Then the response status code is 200
      And the response contains the category "<title>" with description "<description>"

      Examples:
        | title         | description            |
        | ECSE429       | Software Validation    |
        | High Priority | Due before the weekend |

    # Alternate flow
    @alternate
    Scenario Outline: Find a category in the list of all categories
      When I view all categories
      Then the response status code is 200
      And the list of categories includes "<title>"

      Examples:
        | title         |
        | ECSE429       |
        | High Priority |

    # Error flow
    @error
    Scenario Outline: View a category that does not exist
      When I view the category with id "<id>"
      Then the response status code is 404
      And the error message "Could not find an instance with categories/<id>" is returned

      Examples:
        | id    |
        | 99999 |
        | abc   |

  @update
  Rule: Update a category
    As a user I want to update a category to keep its details accurate when my work changes

    Background:
      Given the following categories exist
        | title   | description         |
        | ECSE429 | Software Validation |

    # Normal flow: POST amends only the fields in the body.
    @normal
    Scenario Outline: Amend one field of a category
      When I send a POST update to the category "ECSE429" with the fields
        | field   | value   |
        | <field> | <value> |
      Then the response status code is 200
      And the category "ECSE429" has <field> "<value>"
      And the category "ECSE429" has <other_field> "<other_value>"

      Examples:
        | field       | value            | other_field | other_value         |
        | description | Testing course   | title       | ECSE429             |
        | title       | ECSE429 Winter   | description | Software Validation |

    # Alternate flow: PUT replaces the category, so omitted fields are reset (BUG-04).
    @alternate
    Scenario Outline: Replace a category
      When I send a PUT update to the category "ECSE429" with the fields
        | field | value   |
        | title | <title> |
      Then the response status code is 200
      And the category "ECSE429" has title "<title>"
      And the category "ECSE429" has description ""

      Examples:
        | title          |
        | ECSE429 Winter |
        | Validation     |

    # Error flow: PUT without a title is rejected even though Swagger calls it an amend (BUG-04).
    @error
    Scenario Outline: Update a category with invalid fields
      When I send a <method> update to the category "ECSE429" with the fields
        | field   | value   |
        | <field> | <value> |
      Then the response status code is 400
      And the error message "<message>" is returned
      And the category "ECSE429" has title "ECSE429"
      And the category "ECSE429" has description "Software Validation"

      Examples:
        | method | field       | value    | message                                     |
        | PUT    | description | No title | title : field is mandatory                  |
        | PUT    | title       |          | Failed Validation: title : can not be empty |
        | POST   | title       |          | Failed Validation: title : can not be empty |

    # Error flow
    @error
    Scenario Outline: Update a category that does not exist
      When I send a <method> update with title "New title" to the category with id "<id>"
      Then the response status code is 404
      And the error message "<message>" is returned

      Examples:
        | method | id    | message                                                   |
        | POST   | 99999 | No such category entity instance with GUID or ID 99999 found |
        | PUT    | 99999 | Invalid GUID for 99999 entity category                    |

  @delete
  Rule: Delete a category
    As a user I want to delete a category to remove groupings I no longer need

    Background:
      Given the following categories exist
        | title         | description            |
        | ECSE429       | Software Validation    |
        | High Priority | Due before the weekend |

    # Normal flow
    @normal
    Scenario Outline: Delete a category
      When I delete the category "<title>"
      Then the response status code is 200
      And the category "<title>" no longer exists

      Examples:
        | title         |
        | ECSE429       |
        | High Priority |

    # Alternate flow
    @alternate
    Scenario Outline: Delete a category that still contains work
      Given a <resource> titled "<item>" exists
      And the <resource> "<item>" is in the category "ECSE429"
      When I delete the category "ECSE429"
      Then the response status code is 200
      And the category "ECSE429" no longer exists
      And the <resource> "<item>" still exists

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |

    # Error flow
    @error
    Scenario Outline: Delete a category that does not exist
      When I delete the category with id "<id>"
      Then the response status code is 404
      And the error message "Could not find any instances with categories/<id>" is returned

      Examples:
        | id    |
        | 99999 |
        | abc   |

  @add-work
  Rule: Add work to a category
    As a user I want to add todos and projects to a category to find related work in one place

    Background:
      Given the following categories exist
        | title         | description            |
        | ECSE429       | Software Validation    |
        | High Priority | Due before the weekend |
      And a todo titled "Write report" exists
      And a project titled "Final Project" exists

    # Normal flow
    @normal
    Scenario Outline: Add an item to a category
      When I add the <resource> "<item>" to the category "ECSE429"
      Then the response status code is 201
      And the category "ECSE429" includes the <resource> "<item>"

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |

    # Alternate flow
    @alternate
    Scenario Outline: Add an item to a second category
      Given the <resource> "<item>" is in the category "ECSE429"
      When I add the <resource> "<item>" to the category "High Priority"
      Then the response status code is 201
      And the category "ECSE429" includes the <resource> "<item>"
      And the category "High Priority" includes the <resource> "<item>"

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |

    # Error flow: returns 404, while Swagger lists only 201 and 400 (BUG-03).
    @error
    Scenario Outline: Add an item to a category that does not exist
      When I add the <resource> "<item>" to a category that does not exist
      Then the response status code is 404
      And the error message contains "Could not find parent thing for relationship"

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |

    # Error flow: returns 404, while Swagger lists only 201 and 400 (BUG-03).
    @error
    Scenario Outline: Add an item that does not exist to a category
      When I add a <resource> that does not exist to the category "ECSE429"
      Then the response status code is 404
      And the error message contains "Could not find thing matching value for id"
      And the category "ECSE429" has no related <resource>

      Examples:
        | resource |
        | todo     |
        | project  |

  @remove-work
  Rule: Remove work from a category
    As a user I want to remove todos and projects from a category to keep the category relevant

    Background:
      Given the following categories exist
        | title         | description            |
        | ECSE429       | Software Validation    |
        | High Priority | Due before the weekend |
      And a todo titled "Write report" exists
      And a project titled "Final Project" exists
      And the todo "Write report" is in the category "ECSE429"
      And the project "Final Project" is in the category "ECSE429"

    # Normal flow
    @normal
    Scenario Outline: Remove an item from a category
      When I remove the <resource> "<item>" from the category "ECSE429"
      Then the response status code is 200
      And the category "ECSE429" does not include the <resource> "<item>"
      And the <resource> "<item>" still exists

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |

    # Alternate flow
    @alternate
    Scenario Outline: Remove an item from only one of its categories
      Given the <resource> "<item>" is in the category "High Priority"
      When I remove the <resource> "<item>" from the category "ECSE429"
      Then the response status code is 200
      And the category "ECSE429" does not include the <resource> "<item>"
      And the category "High Priority" includes the <resource> "<item>"

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |

    # Error flow
    @error
    Scenario Outline: Remove an item that is not in the category
      When I remove the <resource> "<item>" from the category "High Priority"
      Then the response status code is 404
      And the error message contains "Could not find any instances with categories/"
      And the category "ECSE429" includes the <resource> "<item>"

      Examples:
        | resource | item          |
        | todo     | Write report  |
        | project  | Final Project |
