Feature: rbld status
  As a CLI user
  I want to be able to list modified environments with rbld status

  Scenario: status help succeeds and usage is printed
    Given I successfully request help for rbld status
    Then help output should contain:
      """
      List modified environments
      """

  Scenario: no modified environments
    Given non-modified environments:
      | test-env:initial |
      | test-env:v001    |
    When I run `rbld status`
    Then the exit status should be 0
    And the output should not contain "test-env:initial"
    And the output should not contain "test-env:v001"

  Scenario: one modified environment
    Given modified environment test-env:v001
    And non-modified environment test-env:initial
    When I run `rbld status`
    Then the exit status should be 0
    And the output should contain "modified: test-env:v001"
    And the output should not contain "test-env:initial"

  Scenario: two modified environments
    Given modified environments:
      | test-env:initial |
      | test-env:v001    |
    When I run `rbld status`
    Then the exit status should be 0
    And the output should contain "modified: test-env:initial"
    And the output should contain "modified: test-env:v001"
