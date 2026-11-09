@projects
Feature: Add a todo to a project
  As a student, I want to add todos to a project,
  so that I can see all the work a project needs in one place.

  Background:
    Given the Todo Manager API is running
    And a project titled "ECSE429 Project" exists

  # Normal flow
  @normal
  Scenario: Add an existing todo to a project
    Given a todo titled "Write report" exists
    When I add the todo "Write report" to the project "ECSE429 Project"
    Then the response status code is 201
    And the project "ECSE429 Project" includes the todo "Write report"
    And the todo "Write report" is a task of the project "ECSE429 Project"

  # Alternate flow
  @alternate
  Scenario: Add a new todo to a project
    When I add a new todo titled "Prepare slides" to the project "ECSE429 Project"
    Then the response status code is 201
    And the project "ECSE429 Project" includes the todo "Prepare slides"

  # Error flow
  @error
  Scenario: Add a todo to a project that does not exist
    Given a todo titled "Write report" exists
    When I add the todo "Write report" to a project that does not exist
    Then the response status code is 404
    And the error message contains "Could not find parent thing for relationship"
