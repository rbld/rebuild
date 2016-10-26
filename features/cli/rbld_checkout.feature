Feature: rbld checkout
  As a CLI user
  I want to be able to discard environment modifications with rbld checkout

  Background:
    Given existing environments:
    |test-env:initial|
    |test-env:v001   |

  Scenario: checkout help succeeds and usage is printed
    Given I successfully request help for rbld checkout
    Then help output should contain:
    """
    Discard environment modifications
    """

  Scenario Outline: checkout of non-existing environment
    When I run `rbld checkout <environment name>`
    Then it should pass with empty output

    Examples:
      | environment name    |
      | nonexisting         |
      | nonexisting:sometag |

  Scenario Outline: checkout of existing environment
    Given environment test-env:v001 is <modified or not modified>
    When I run `rbld checkout test-env:v001`
    Then it should pass with empty output
    And environment test-env:v001 should not be marked as modified

    Examples:
      | modified or not modified |
      | modified                 |
      | not modified             |
