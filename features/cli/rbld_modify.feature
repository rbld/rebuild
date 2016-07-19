Feature: rbld modify
  As a CLI user
  I want to be able to modify existing environments with rbld modify

  Background:
    Given existing environment test-env:initial
      And existing environment test-env:v001

  Scenario: modify help exit status of 0
    When I run `rbld modify --help`
    Then the exit status should be 0

  Scenario: modify help header is printed
    Given I successfully run `rbld modify --help`
    Then the output should contain:
    """
    Modify a local environment
    """

  Scenario: error code returned for non-existing environments
    When I run `rbld modify nonexisting`
    Then the exit status should not be 0

  Scenario: error printed for non-existing environments
    When I run `rbld modify nonexisting`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Unknown environment nonexisting:initial
      """

  Scenario: error printed for non-existing environment with tag
    When I run `rbld modify nonexisting:sometag`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Unknown environment nonexisting:sometag
      """

  Scenario: non-interactive modification of environment with tag
    When I successfully run `rbld modify test-env:v001 -- echo Hello world!`
    Then the output should contain:
      """
      >>> rebuild env test-env:v001-M
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env:v001-M
      """
    And environment test-env:v001 should be marked as modified

  Scenario: non-interactive modification of environment without tag
    When I successfully run `rbld modify test-env -- echo Hello world!`
    Then the output should contain:
      """
      >>> rebuild env test-env:initial-M
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env:initial-M
      """
    And environment test-env should be marked as modified

  Scenario: interactive modification of environment
    When I run `rbld modify test-env:v001` interactively
    And I type "echo Hello interactive world!"
    And I close the stdin stream
    Then the exit status should be 0
    Then the output should contain:
      """
      >>> rebuild env test-env:v001-M interactive
      >>> Press CTRL-D do leave
      Hello interactive world!
      <<< rebuild env test-env:v001-M
      """
    And environment test-env:v001 should be marked as modified

  Scenario: hostname of environment set to the environment name with modified sign
    When I successfully run `rbld modify test-env:v001 -- hostname`
    Then the output should contain:
      """
      >>> rebuild env test-env:v001-M
      >>> hostname
      test-env:v001-M
      <<< rebuild env test-env:v001-M
      """

  Scenario Outline: rbld modify propagates exit code
    When I run `rbld modify test-env:v001 -- exit <internal status>`
    Then the exit status should be <external status>

    Examples:
      | internal status | external status |
      |  0              | 0               |
      |  5              | 5               |
