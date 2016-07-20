Feature: rbld run
  As a CLI user
  I want to be able to run existing environments with rbld run

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001

  Scenario: run help exit status of 0
    When I run `rbld run --help`
    Then the exit status should be 0

  Scenario: run help header is printed
    Given I successfully run `rbld run --help`
    Then the output should contain:
    """
    Run command in a local environment
    """

  Scenario: error code returned for non-existing environments
    When I run `rbld run nonexisting`
    Then the exit status should not be 0

  Scenario: error printed for non-existing environments
    When I run `rbld run nonexisting`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Unknown environment nonexisting:initial
      """

  Scenario: error printed for non-existing environment with tag
    When I run `rbld run nonexisting:sometag`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Unknown environment nonexisting:sometag
      """

  Scenario: non-interactive running of environment with tag
    When I successfully run `rbld run test-env:v001 -- echo Hello world!`
    Then the output should contain exactly:
      """
      >>> rebuild env test-env:v001
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env:v001
      """

  Scenario: non-interactive running of environment without tag
    When I successfully run `rbld run test-env -- echo Hello world!`
    Then the output should contain exactly:
      """
      >>> rebuild env test-env:initial
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env:initial
      """

  Scenario: interactive running of environment
    When I run `rbld run test-env:v001` interactively
    And I type "echo Hello interactive world!"
    And I close the stdin stream
    Then the exit status should be 0
    And the output should contain exactly:
      """
      >>> rebuild env test-env:v001 interactive
      >>> Press CTRL-D do leave
      Hello interactive world!
      <<< rebuild env test-env:v001
      """

  Scenario: warning printed when running modified environment
    Given environment test-env:v001 is modified
    When I successfully run `rbld run test-env:v001 -- echo Hello world!`
    Then the output should contain exactly:
      """
      WARNING: Environment is modified, running original version
      >>> rebuild env test-env:v001
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env:v001
      """

  Scenario: hostname of environment set to the environment name
    When I successfully run `rbld run test-env:v001 -- hostname`
    Then the output should contain exactly:
      """
      >>> rebuild env test-env:v001
      >>> hostname
      test-env:v001
      <<< rebuild env test-env:v001
      """

  Scenario Outline: rbld run propagates exit code
    When I run `rbld run test-env:v001 -- exit <internal status>`
    Then the exit status should be <external status>

    Examples:
      | internal status | external status |
      |  0              | 0               |
      |  5              | 5               |
