Feature: rbld checkout
  As a CLI user
  I want to be able to discard environment modifications with rbld checkout

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001

  Scenario: checkout help exit status of 0
    When I run `rbld checkout --help`
    Then the exit status should be 0

  Scenario: checkout help header is printed
    Given I successfully run `rbld checkout --help`
    Then the output should contain:
    """
    Discard environment modifications
    """

  Scenario: checkout of non-existing environment is allowed
    When I run `rbld checkout nonexisting`
    Then the exit status should be 0
    And the output should be empty

  Scenario: checkout of non-existing environment with tag is allowed
    When I run `rbld checkout nonexisting:sometag`
    Then the exit status should be 0
    And the output should be empty

  Scenario: checkout of modified environment
    Given environment test-env:v001 is modified
    When I run `rbld checkout test-env:v001`
    Then the exit status should be 0
    And the output should be empty
    And environment test-env:v001 should not be marked as modified

  Scenario: checkout of non-modified environment
    Given environment test-env:v001 is not modified
    When I run `rbld checkout test-env:v001`
    Then the exit status should be 0
    And the output should be empty
    And environment test-env:v001 should not be marked as modified
