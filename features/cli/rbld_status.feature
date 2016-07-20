Feature: rbld status
  As a CLI user
  I want to be able to list modified environments with rbld status

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001

  Scenario: status help exit status of 0
    When I run `rbld status --help`
    Then the exit status should be 0

  Scenario: status help header is printed
    Given I successfully run `rbld status --help`
    Then the output should contain:
    """
    List modified environments
    """

  Scenario: no modified environments
    Given environment test-env is not modified
    And environment test-env:v001 is not modified
    When I run `rbld status`
    Then the exit status should be 0
    And the output should not contain "test-env:initial"
    And the output should not contain "test-env:v001"

  Scenario: one modified environment
    Given environment test-env is not modified
    And environment test-env:v001 is modified
    When I run `rbld status`
    Then the exit status should be 0
    And the output should contain "modified: test-env:v001"

  Scenario: two modified environments
    Given environment test-env is modified
    And environment test-env:v001 is modified
    When I run `rbld status`
    Then the exit status should be 0
    And the output should contain "modified: test-env:initial"
    And the output should contain "modified: test-env:v001"
