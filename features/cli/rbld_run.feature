Feature: rbld run
  As a CLI user
  I want to be able to run existing environments with rbld run

  Background:
    Given existing environments:
      | test-env:initial |
      | test-env:v001    |

  Scenario: run help succeeds and usage is printed
    Given I successfully request help for rbld run
    Then help output should contain "rbld run [OPTIONS] [ENVIRONMENT[:TAG]]"
    And help output should contain "Interactive mode: opens shell in the specified enviroment"
    And help output should contain "rbld run [OPTIONS] [ENVIRONMENT[:TAG]] -- COMMANDS"
    And help output should contain "Scripting mode: runs COMMANDS in the specified environment"
    And help output should contain "Run command in a local environment"
    And help output should match "-h, --help.*Print usage"

  Scenario Outline: error printed for non-existing environments
    When I run `rbld run <non-existing environment name>`
    Then it should fail with:
      """
      ERROR: Unknown environment <full environment name>
      """

    Examples:
      | non-existing environment name | full environment name |
      | nonexisting                   | nonexisting:initial   |
      | nonexisting:sometag           | nonexisting:sometag   |

  Scenario Outline: non-interactive running of environments
    When I successfully run `rbld run <environment name> -- echo Hello world!`
    Then it should pass with exactly:
      """
      >>> rebuild env <environment host name>
      >>> echo Hello world!
      Hello world!
      <<< rebuild env <environment host name>
      """

    Examples:
      | environment name | environment host name |
      | test-env:v001    | test-env-v001         |
      | test-env         | test-env-initial      |

  Scenario: non-interactive run without command line options separator
    When I successfully run `rbld run test-env:v001 echo Hello world!`
    Then it should pass with exactly:
      """
      >>> rebuild env test-env-v001
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env-v001
      """

  Scenario Outline: interactive running of environment
    When I run `rbld run <environment name>` interactively
    And I type "echo Hello interactive world!"
    And I close the stdin stream
    Then it should pass with exactly:
      """
      >>> rebuild env <environment host name> interactive
      >>> Press CTRL-D do leave
      Hello interactive world!
      <<< rebuild env <environment host name>
      """

    Examples:
      | environment name | environment host name |
      | test-env:v001    | test-env-v001         |
      | test-env         | test-env-initial      |

  Scenario: warning printed when running modified environment
    Given environment test-env:v001 is modified
    When I run `rbld run test-env:v001 -- echo Hello world!`
    Then it should pass with exactly:
      """
      WARNING: Environment is modified, running original version
      >>> rebuild env test-env-v001
      >>> echo Hello world!
      Hello world!
      <<< rebuild env test-env-v001
      """

  Scenario: hostname of environment set to the environment name
    When I run `rbld run test-env:v001 -- hostname`
    Then it should pass with exactly:
      """
      >>> rebuild env test-env-v001
      >>> hostname
      test-env-v001
      <<< rebuild env test-env-v001
      """

  Scenario Outline: rbld run propagates exit code
    When I run `rbld run test-env:v001 -- exit <status>`
    Then the exit status should be <status>

    Examples:
      | status |
      |  0     |
      |  5     |

  Scenario: bootstrap tracing is disabled by default
    When I run `rbld run test-env:v001 -- echo Hi`
    Then the output should not contain "Bootstrap tracing enabled"

  Scenario: bootstrap tracing is enabled by RBLD_BOOTSTRAP_TRACE environment variable
    Given I set the environment variables to:
      | variable             | value |
      | RBLD_BOOTSTRAP_TRACE | 1     |
    When I run `rbld run test-env:v001 -- echo Hi`
    Then the output should contain "Bootstrap tracing enabled"
