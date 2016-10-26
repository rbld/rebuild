Feature: rbld save
  As a CLI user
  I want to be able to save an existing environment to file with rbld save

  Scenario: save help succeeds and usage is printed
    Given I successfully request help for rbld save
    Then help output should contain:
    """
    Save local environment to file
    """

  Scenario: environment name not specified
    Given I run `rbld save`
    Then it should fail with:
    """
    ERROR: Environment name not specified
    """

  Scenario Outline: save a non-existing environment
    Given a file named "env.rbld" does not exist
    When I run `rbld save <non-existing environment name> env.rbld`
    Then it should fail with:
      """
      ERROR: Unknown environment <full environment name>
      """
    And the file "env.rbld" should not exist

    Examples:
      | non-existing environment name | full environment name |
      | non-existing                  | non-existing:initial  |
      | non-existing:sometag          | non-existing:sometag  |

  Scenario Outline: save a non-existing environment with default file name
    Given a file named "<default file name>" does not exist
    When I run `rbld save <non-existing environment name>`
    Then it should fail with:
      """
      ERROR: Unknown environment <full environment name>
      """
    And the file "<default file name>" should not exist

    Examples:
      | non-existing environment name | full environment name | default file name           |
      | non-existing                  | non-existing:initial  | non-existing-initial.rbld |
      | non-existing:sometag          | non-existing:sometag  | non-existing-sometag        |

  Scenario: save an existing environment
    Given existing environment test-env
    And a file named "saved-test-env.rbld" does not exist
    When I run `rbld save test-env saved-test-env.rbld`
    Then the output should contain "Successfully saved environment test-env:initial to saved-test-env.rbld"
    And the exit status should be 0
    And file named "saved-test-env.rbld" should contain a valid saved environment test-env

  Scenario: save an existing environment with default file name
    Given existing environment test-env
    And a file named "test-env-initial.rbld" does not exist
    When I run `rbld save test-env`
    Then the output should contain "Successfully saved environment test-env:initial to test-env-initial.rbld"
    And the exit status should be 0
    And file named "test-env-initial.rbld" should contain a valid saved environment test-env

  Scenario: save overwrites existing files
    Given existing environment test-env
    And an empty file named "test-env-initial.rbld"
    When I run `rbld save test-env`
    Then the output should contain "Successfully saved environment test-env:initial to test-env-initial.rbld"
    And the exit status should be 0
    And file named "test-env-initial.rbld" should contain a valid saved environment test-env

  Scenario: save a modified environment
    Given environment test-env is modified
    And a file named "test-env.rbld" does not exist
    When I run `rbld save test-env test-env.rbld`
    Then the output should match:
      """
      WARNING: Environment is modified, saving original version
      .*
      Successfully saved environment test-env:initial to test-env.rbld
      """
    And the exit status should be 0
    And file named "test-env.rbld" should contain a valid saved environment test-env
