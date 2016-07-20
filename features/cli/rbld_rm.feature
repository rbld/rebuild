Feature: rbld rm
  As a CLI user
  I want to be able to remove existing environments with rbld rm

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001

  Scenario: rm help exit status of 0
    When I run `rbld rm --help`
    Then the exit status should be 0

  Scenario: rm help header is printed
    Given I successfully run `rbld rm --help`
    Then the output should contain:
    """
    Remove local environment
    """

  Scenario: error code returned for non-existing environments
    When I run `rbld rm nonexisting`
    Then the exit status should not be 0

  Scenario: error printed for non-existing environments
    When I run `rbld rm nonexisting`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Unknown environment nonexisting:initial
      """

  Scenario: error printed for non-existing environment with tag
    When I run `rbld rm nonexisting:sometag`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Unknown environment nonexisting:sometag
      """

  Scenario: removal of existing environment with tag
    When I successfully run `rbld rm test-env:v001`
    Then environment test-env:v001 should not exist
    But environment test-env should exist

  Scenario: removal of existing environment without tag
    When I successfully run `rbld rm test-env`
    Then environment test-env should not exist
    But environment test-env:v001 should exist
