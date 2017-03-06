Feature: rbld
  As a CLI user
  I want to interfere with system via main script called rbld

  Scenario: rbld _unknown_command_ fails with error
    Given I run `rbld _unknown_command_`
    Then it should fail with:
    """
    ERROR: Unknown command: _unknown_command_
    """

  Scenario: rbld help _unknown_command_ fails with error
    Given I run `rbld help _unknown_command_`
    Then it should fail with:
    """
    ERROR: Unknown command: _unknown_command_
    """

  Scenario: there is no log by default
    Given I run `rbld`
    Then the output should not contain "INFO: ARGV:"

  Scenario: log is enabled by RBLD_LOG_LEVEL environment variable
    Given I set the environment variables to:
      | variable       | value |
      | RBLD_LOG_LEVEL | debug |
    When I run `rbld`
    Then the output should contain "INFO: ARGV:"

  Scenario Outline: various log levels supported
    Given I set the environment variables to:
      | variable       | value   |
      | RBLD_LOG_LEVEL | <level> |
    When I run `rbld`
    Then the output <should or should not> contain "INFO: ARGV:"

    Examples:
      | level   | should or should not |
      | debug   | should               |
      | info    | should               |
      | warn    | should not           |
      | error   | should not           |
      | fatal   | should not           |
      | unknown | should not           |


  Scenario: log is redirected to file by RBLD_LOG_FILE environment variable
    Given I set the environment variables to:
      | variable       | value    |
      | RBLD_LOG_LEVEL | debug    |
      | RBLD_LOG_FILE  | rbld.log |
    When I run `rbld`
    Then the output should not contain "INFO: ARGV:"
    And a file "rbld.log" should contain "INFO: ARGV:"

  Scenario: stack backtrace is not printed on incorrect command line
    When I run `rbld run --wrong-opt`
    Then the output should not contain "<main>"
