@categories @story9
Feature: Delete a category
  As a user I want to delete a category to get rid of groupings I no longer need.

  Background:
    Given the Todo Manager API is running
    And the following categories exist
      | title          | description         |
      | Old course     | Finished last term  |
      | Cancelled lab  | No longer offered   |
      | Keep this one  | Still in use        |

  @normal
  Scenario Outline: Delete a category and keep the other categories
    When I delete the category "<title>"
    Then the response status code is 200
    And the category "<title>" does not exist
    And the category "Keep this one" still exists

    Examples:
      | title         |
      | Old course    |
      | Cancelled lab |

  @alternate
  Scenario Outline: Delete a category that contains a todo and a project and keep them
    Given a todo titled "<todo>" exists
    And a project titled "<project>" exists
    And the todo "<todo>" is in the category "Old course"
    And the project "<project>" is in the category "Old course"
    When I delete the category "Old course"
    Then the response status code is 200
    And the category "Old course" does not exist
    And the todo "<todo>" still exists
    And the project "<project>" still exists

    Examples:
      | todo         | project       |
      | Write report | Final Project |
      | Old task     | Part A        |

  # BUG-08: DELETE gives a different "not found" message than GET, POST and PUT.
  @error
  Scenario Outline: Delete a category that does not exist
    When I delete the category with id "<id>"
    Then the response status code is 404
    And the error message "Could not find any instances with categories/<id>" is returned
    And the number of categories is unchanged

    Examples:
      | id     |
      | 999999 |
      | abc    |
