@categories @story10
Feature: Add todos and projects to a category
  As a user I want to link todos and projects to a category to get all the related work in one place.

  Background:
    Given the Todo Manager API is running
    And a category titled "ECSE429" exists
    And a category titled "High Priority" exists
    And the category "ECSE429" has no related todo
    And the category "ECSE429" has no related project

  @normal
  Scenario Outline: Add an existing todo or project to a category
    Given a <resource> titled "<item>" exists
    When I add the <resource> "<item>" to the category "ECSE429"
    Then the response status code is 201
    And the category "ECSE429" includes the <resource> "<item>"

    Examples:
      | resource | item            |
      | todo     | Write report    |
      | todo     | Submit proposal |
      | project  | Final Project   |

  @alternate
  Scenario Outline: Add a todo or project that already belongs to another category
    Given a <resource> titled "<item>" exists
    And the <resource> "<item>" is in the category "High Priority"
    When I add the <resource> "<item>" to the category "ECSE429"
    Then the response status code is 201
    And the category "ECSE429" includes the <resource> "<item>"
    And the category "High Priority" includes the <resource> "<item>"

    Examples:
      | resource | item          |
      | todo     | Shared setup  |
      | project  | Final Project |

  # BUG-03: the API returns 404, but Swagger only documents 201 and 400.
  @error
  Scenario Outline: Add a todo or project to a category that does not exist
    Given a <resource> titled "<item>" exists
    When I add the <resource> "<item>" to a category that does not exist
    Then the response status code is 404
    And the error message contains "Could not find parent thing for relationship"

    Examples:
      | resource | item          |
      | todo     | Write report  |
      | project  | Final Project |

  # BUG-03: the API returns 404, but Swagger only documents 201 and 400.
  @error
  Scenario Outline: Add a todo or project that does not exist to a category
    When I add a <resource> that does not exist to the category "ECSE429"
    Then the response status code is 404
    And the error message contains "Could not find thing matching value for id"
    And the category "ECSE429" has no related <resource>

    Examples:
      | resource |
      | todo     |
      | project  |
