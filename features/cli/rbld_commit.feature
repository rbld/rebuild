Feature: rbld commit
  As a CLI user
  I want to be able to commit environment modifications with rbld commit

  Background:
    Given existing environments:
      | test-env:initial |
      | test-env:v001    |
    And non-existing environment test-env:v002

  Scenario: commit help succeeds and usage is printed
    Given I successfully request help for rbld commit
    Then help output should contain:
    """
    Commit environment modifications
    """

  Scenario Outline: commit non-existing environment
    When I run `rbld commit --tag some_new_tag <non-existing environment name>`
    Then it should fail with:
    """
    ERROR: No changes to commit for <full environment name>
    """

    Examples:
      | non-existing environment name | full environment name |
      | non-existing                  | non-existing:initial  |
      | non-existing:sometag          | non-existing:sometag  |

  Scenario: commit environment with incorrect tag
    Given environment test-env:v001 is modified
    When I run `rbld commit --tag incorr~ect test-env:v001`
    Then it should fail with:
    """
    ERROR: Invalid new tag (incorr~ect), it may contain a-z, A-Z, 0-9, - and _ characters only
    """
    And environment test-env:v001 should be marked as modified

  Scenario: commit environment which is not modified
    Given environment test-env:v001 is not modified
    When I run `rbld commit --tag v002 test-env:v001`
    Then it should fail with:
    """
    ERROR: No changes to commit for test-env:v001
    """

  Scenario: commit environment which is modified
    Given environment test-env:v001 is modified
    And I run `rbld commit --tag v002 test-env:v001`
    Then it should pass with:
    """
    Creating new environment test-env:v002...
    """
    And environment test-env:v002 should exist
