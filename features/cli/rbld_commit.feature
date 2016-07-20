Feature: rbld commit
  As a CLI user
  I want to be able to commit environment modifications with rbld commit

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001
      And non-existing environment test-env:v002

  Scenario: commit help exit status of 0
    When I run `rbld commit --help`
    Then the exit status should be 0

  Scenario: commit help header is printed
    Given I successfully run `rbld commit --help`
    Then the output should contain:
    """
    Commit environment modifications
    """

  Scenario: commit non-existing environment
    When I run `rbld commit --tag sometag non-existing`
    Then the exit status should not be 0
    And the output should contain:
    """
    ERROR: No changes to commit for non-existing:initial
    """

  Scenario: commit non-existing environment with tag
    When I run `rbld commit --tag sometag2 non-existing:sometag`
    Then the exit status should not be 0
    And the output should contain:
    """
    ERROR: No changes to commit for non-existing:sometag
    """

  Scenario: commit environment with incorrect tag
    Given environment test-env:v001 is modified
    When I run `rbld commit --tag incorr~ect test-env:v001`
    Then the exit status should not be 0
    And the output should contain:
    """
    ERROR: Invalid new tag (incorr~ect), it may contain a-z, A-Z, 0-9, - and _ characters only
    """
    And environment test-env:v001 should be marked as modified

  Scenario: commit environment which is not modified
    Given environment test-env:v001 is not modified
    When I run `rbld commit --tag v002 test-env:v001`
    Then the exit status should not be 0
    And the output should contain:
    """
    ERROR: No changes to commit for test-env:v001
    """

  Scenario: commit environment which is modified
    Given environment test-env:v001 is modified
    And I successfully run `rbld commit --tag v002 test-env:v001`
    Then the output should contain:
    """
    Creating new environment test-env:v002...
    """
