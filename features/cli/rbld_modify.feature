Feature: rbld modify
  As a CLI user
  I want to be able to modify existing environments with rbld modify

  Background:
    Given existing non-modified environments:
    | test-env:initial |
    | test-env:v001    |

  Scenario: modify help succeeds and usage is printed
    Given I successfully request help for rbld modify
    Then help output should contain "rbld modify [OPTIONS] [ENVIRONMENT[:TAG]]"
    And help output should contain "Interactive mode: opens shell in the specified enviroment"
    And help output should contain "rbld modify [OPTIONS] [ENVIRONMENT[:TAG]] -- COMMANDS"
    And help output should contain "Scripting mode: runs COMMANDS in the specified environment"
    And help output should contain "Modify a local environment"
    And help output should match "-p, --privileged.*Run environment with superuser privileges"
    And help output should match "-h, --help.*Print usage"

  Scenario Outline: error code returned for non-existing environments
    When I run `rbld modify <non-existing environment name>`
    Then it should fail with:
    """
    ERROR: Unknown environment <full environment name>
    """

    Examples:
      | non-existing environment name | full environment name |
      | non-existing                  | non-existing:initial  |
      | non-existing:sometag          | non-existing:sometag  |

  Scenario Outline: non-interactive modification of environment
    When I successfully run `rbld modify <environment name> -- echo Hello world!`
    Then it should pass with:
      """
      >>> rebuild env <environment host name>-M
      >>> echo Hello world!
      Hello world!
      <<< rebuild env <environment host name>-M
      """
    And environment <environment name> should be marked as modified

    Examples:
      | environment name | environment host name |
      | test-env:v001    | test-env-v001         |
      | test-env         | test-env-initial      |

  Scenario Outline: interactive modification of environment
    When I run `rbld modify <environment name>` interactively
    And I type "echo Hello interactive world!"
    And I close the stdin stream
    Then it should pass with:
      """
      >>> rebuild env <environment host name>-M interactive
      >>> Press CTRL-D do leave
      Hello interactive world!

      <<< rebuild env <environment host name>-M
      """
    And environment <environment name> should be marked as modified

    Examples:
      | environment name | environment host name |
      | test-env:v001    | test-env-v001         |
      | test-env         | test-env-initial      |

  Scenario: hostname of environment set to the environment name with modified sign
    When I run `rbld modify test-env:v001 -- hostname`
    Then it should pass with:
      """
      >>> rebuild env test-env-v001-M
      >>> hostname
      test-env-v001-M
      <<< rebuild env test-env-v001-M
      """

  Scenario Outline: rbld modify propagates exit code
    When I run `rbld modify test-env:v001 -- exit <status>`
    Then the exit status should be <status>

    Examples:
      | status |
      |  0     |
      |  5     |

  Scenario Outline: multiple environment modifications supported
    Given non-existing environment test-env:multimod
    Given I successfully run `rbld modify test-env -- echo Hi` for <x> times
    Then environment test-env should be marked as modified
    When I successfully run `rbld commit --tag multimod test-env`
    And I successfully run `rbld run test-env:multimod -- echo Hello from multimod`
    Then the output should contain "Hello from multimod"

    Examples:
      | x   |
      | 2   |

    @slow
    Examples:
      | x   |
      | 130 |

    Scenario: bootstrap tracing is disabled by default
      When I run `rbld modify test-env:v001 -- echo Hi`
      Then the output should not contain "Bootstrap tracing enabled"

    Scenario: bootstrap tracing is enabled by RBLD_BOOTSTRAP_TRACE environment variable
      Given I set the environment variables to:
        | variable             | value |
        | RBLD_BOOTSTRAP_TRACE | 1     |
      When I run `rbld modify test-env:v001 -- echo Hi`
      Then the output should contain "Bootstrap tracing enabled"

    Scenario: during modification, environments do not have superuser privileges by default
      Given a file named "test.ko" with "DUMMY"
      When I run `rbld run test-env -- sudo insmod test.ko`
      Then it should fail with "Operation not permitted"

    Scenario Outline: during modification, environments may be executed with superuser priviledges
      Given a file named "test.ko" with "DUMMY"
      When I run `rbld run <privileged flag> test-env -- sudo insmod test.ko`
      Then it should fail with "invalid module format"

      Examples:
        | privileged flag |
        | --privileged    |
        | -p              |
