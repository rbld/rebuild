Feature: rbld load
  As a CLI user
  I want to be able to load an environment from file with rbld load

  Scenario: load help succeeds and usage is printed
    Given I run `rbld load --help`
    Then it should pass with:
    """
    Load environment from file
    """

  Scenario: file name not specified
    Given I run `rbld load`
    Then it should fail with:
    """
    ERROR: File name must be specified
    """

  Scenario: load environment from non-existing file
    Given a file named "env.rbld" does not exist
    When I run `rbld load env.rbld`
    Then it should fail with:
      """
      ERROR: File env.rbld does not exist
      """

  Scenario Outline: load environment
    Given a file named "env.rbld" contains a saved environment test-env
    And <environment state> environment test-env
    When I run `rbld load env.rbld`
    Then environment test-env should be successfully loaded from "env.rbld"

    Examples:
      | environment state |
      | existing          |
      | non-existing      |
