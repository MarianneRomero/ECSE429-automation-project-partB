@todos
Feature: Mark a todo as done
  As a student, I want to mark a todo as done,
  so that I can keep track of the work I have finished.

  Background:
    Given the Todo Manager API is running
    And the following todos exist
      | title             | doneStatus |
      | Read chapter 4    | false      |
      | Submit assignment | true       |

  # Normal flow
  @normal
  Scenario: Mark an unfinished todo as done
    When I mark the todo "Read chapter 4" as done
    Then the response status code is 200
    And the todo "Read chapter 4" has doneStatus "true"

  # Alternate flow
  @alternate
  Scenario: Mark a todo that is already done as done
    When I mark the todo "Submit assignment" as done
    Then the response status code is 200
    And the todo "Submit assignment" has doneStatus "true"

  # Error flows
  @error
  Scenario: Mark a todo that does not exist as done
    When I mark a todo that does not exist as done
    Then the response status code is 404
    And the error message contains "No such todo entity instance"

  @error
  Scenario Outline: Set the done status to a value that is not a boolean
    When I set the done status of the todo "Read chapter 4" to "<value>"
    Then the response status code is 400
    And the error message "Failed Validation: doneStatus should be BOOLEAN" is returned
    And the todo "Read chapter 4" has doneStatus "false"

    Examples:
      | value |
      | yes   |
      | done  |
