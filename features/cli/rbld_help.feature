Feature: rbld help
  As a CLI user
  I want to be able to obtain usage info with rbld help

  Scenario: rbld help suceeds and header is printed
    Given I run `rbld help`
    Then it should pass with:
    """
    Usage:
      rbld help                Show this help screen
      rbld help COMMAND        Show help for COMMAND
      rbld COMMAND [PARAMS]    Run COMMAND with PARAMS

    rebuild: Zero-dependency, reproducible build environments
    """

  Scenario: List of commands is printed
    Given I run `rbld help`
    Then it should pass with:
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
