Feature: rbld help
  As a CLI user
  I want to be able to obtain usage info with rbld help

  Scenario Outline: rbld help succeeds and header is printed
    Given I run `<command>`
    Then it should pass with:
    """
    Usage:
      rbld help                Show this help screen
      rbld help COMMAND        Show help for COMMAND
      rbld COMMAND [PARAMS]    Run COMMAND with PARAMS

    rebuild: Zero-dependency, reproducible build environments
    """

    Examples:
      | command   |
      | rbld help |
      | rbld      |

  Scenario Outline: List of commands is printed
    Given I run `<command>`
    Then it should pass with:
    """
    Commands:

      checkout
      commit
      create
      deploy
      list
      load
      modify
      publish
      rm
      run
      save
      search
      status
    """

    Examples:
      | command   |
      | rbld help |
      | rbld      |
