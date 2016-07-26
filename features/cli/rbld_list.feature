Feature: rbld list
  As a CLI user
  I want to be able to list existing environments with rbld list

  Background:
    Given existing environments:
      | test-env:initial |
      | test-env:v001    |

  Scenario: list help succeeds and usage is printed
    Given I run `rbld list --help`
    Then it should pass with:
    """
    List local environments
    """

  Scenario: list existing environment
    When I run `rbld list`
    Then it should pass with:
    """
    \ttest-env:initial
    \ttest-env:v001
    """
