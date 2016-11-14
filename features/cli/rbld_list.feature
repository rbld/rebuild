Feature: rbld list
  As a CLI user
  I want to be able to list existing environments with rbld list

  Background:
    Given existing environments:
      | test-env:initial |
      | test-env:v001    |

  Scenario: list help succeeds and usage is printed
    Given I successfully request help for rbld list
    Then help output should contain:
    """
    List local environments
    """

  Scenario: list existing environment
    When I successfully run `rbld list`
    Then the output should contain "test-env:initial"
    And the output should contain "test-env:v001"

  Scenario: correct listing of similar environments
    Given existing environments:
      | samebase1:initial |
      | samebase2:initial |
    When I successfully run `rbld list`
    Then the output should contain "samebase1:initial"
    And the output should contain "samebase2:initial"
