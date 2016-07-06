Feature: rbld help
  As a CLI user
  I want to be able to obtain basic usage info with rbld help

  Scenario: Exit status of 0
    Given I run `rbld help`
    Then the exit status should be 0

  Scenario: Help header is printed
    Given I successfully run `rbld help`

    Then the output should contain:
    """
    Usage:
      rbld help                Show this help screen
      rbld help COMMAND        Show help for COMMAND
      rbld COMMAND [PARAMS]    Run COMMAND with PARAMS

    rebuild: Zero-dependency, reproducible build environments
    """

  Scenario: List of commands is printed
    Given I successfully run `rbld help`

    Then the output should contain:
    """
    Commands:

      checkout
      commit
      create
      deploy
      list
      modify
      publish
      rm
      run
      search
      status
    """
