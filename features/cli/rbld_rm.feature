Feature: rbld rm
  As a CLI user
  I want to be able to remove existing environments with rbld rm

  Background:
    Given existing environments:
    | test-env:initial |
    | test-env:v001    |

  Scenario: rm help succeeds and usage is printed
    Given I run `rbld rm --help`
    Then it should pass with:
    """
    Remove local environment
    """

  Scenario Outline: removal of non-existing environments
    When I run `rbld rm <non-existing environment name>`
    Then it should fail with:
      """
      ERROR: Unknown environment <full environment name>
      """

    Examples:
      | non-existing environment name | full environment name |
      | non-existing                  | non-existing:initial  |
      | non-existing:sometag          | non-existing:sometag  |

  Scenario Outline: removal of existing environments
    When I successfully run `rbld rm <environment being removed>`
    Then environment <environment being removed> should not exist
    But environment <environment not being removed> should exist

    Examples:
      | environment being removed | environment not being removed |
      | test-env:v001             | test-env:initial              |
      | test-env                  | test-env:v001                 |

  Scenario: Removal of modified environment
    Given environment test-env:v001 is modified
    When I run `rbld rm test-env:v001`
    Then it should fail with:
    """
    ERROR: Environment is modified, commit or checkout first
    """
    And environment test-env:v001 should be marked as modified
