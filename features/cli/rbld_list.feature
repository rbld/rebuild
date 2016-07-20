Feature: rbld list
  As a CLI user
  I want to be able to list existing environments with rbld list

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001

  Scenario: list help exit status of 0
    When I run `rbld list --help`
    Then the exit status should be 0

  Scenario: list help header is printed
    Given I successfully run `rbld list --help`
    Then the output should contain:
    """
    List local environments
    """

  Scenario: list existing environment
    When I successfully run `rbld list`
    Then the output should contain:
    """
    \ttest-env:initial
    \ttest-env:v001
    """

