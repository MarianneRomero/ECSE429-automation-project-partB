@todos @story3
Feature: Mark a todo as done
  As a student, I want to mark a todo as done or not done,
  so that I can keep track of the work I have finished.

  Background:
    Given the Todo Manager API is running
    And the following todos exist
      | title             | description      | doneStatus |
      | Read chapter 4    | Software testing | false      |
      | Write lab notes   | Lab 2            | false      |
      | Submit assignment | Assignment 1     | true       |

  @normal
  Scenario Outline: Mark an unfinished todo as done
    When I amend the todo "<title>" with the fields
      | field      | value |
      | doneStatus | true  |
    Then the response status code is 200
    And the todo "<title>" has doneStatus "true"
    And the todo "<title>" keeps its other fields unchanged

    Examples:
      | title           |
      | Read chapter 4  |
      | Write lab notes |

  @alternate
  Scenario Outline: Reopen a finished todo, or mark it as done again
    When I amend the todo "Submit assignment" with the fields
      | field      | value        |
      | doneStatus | <doneStatus> |
    Then the response status code is 200
    And the todo "Submit assignment" has doneStatus "<doneStatus>"
    And the todo "Submit assignment" keeps its other fields unchanged

    Examples:
      | doneStatus |
      | false      |
      | true       |

  @error
  Scenario Outline: Mark a todo that does not exist as done
    When I amend the todo with id "<id>" with the fields
      | field      | value |
      | doneStatus | true  |
    Then the response status code is 404
    And the error message "No such todo entity instance with GUID or ID <id> found" is returned

    Examples:
      | id     |
      | 999999 |
      | abc    |

  @error
  Scenario Outline: Set the done status to a value that is not a boolean
    When I amend the todo "Read chapter 4" with the fields
      | field      | value   |
      | doneStatus | <value> |
    Then the response status code is 400
    And the error message "Failed Validation: doneStatus should be BOOLEAN" is returned
    And the todo "Read chapter 4" is unchanged

    Examples:
      | value |
      | yes   |
      | done  |
