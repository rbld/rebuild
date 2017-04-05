@with-plugin
Feature: plugins support
  As a rebuild developer
  I want to be able to extend Rebuild CLI functionality with plugins

  Scenario: Rebuild CLI notifies plugins on start
    When I successfully run `rbld help`
    Then the output should contain "Hello from Rebuild CLI plugin"

  Scenario: Rebuild CLI notifies plugins on command execution
    When I successfully run `rbld list`
    Then the output should contain "Hello from Rebuild CLI plugin"
    And the output should contain "Hello from Rebuild CLI plugin command 'list()' handler"

  Scenario: Rebuild CLI may extend set of Rebuild CLI commands
    When I successfully run `rbld help hello`
    Then the output should contain "Hello from rbld hello 'usage' handler"
    When I successfully run `rbld hello`
    Then the output should contain "Hello from rbld hello 'run' handler"

  Scenario: Plugins may interrupt Rebuild CLI execution
    Given I set the environment variables to:
      | variable              | value |
      | RBLD_HELLO_FAIL_START | 1     |
    When I run `rbld help`
    Then the exit status should be 100

  Scenario: Plugins may interrupt Rebuild CLI command execution
    Given I set the environment variables to:
      | variable                | value |
      | RBLD_HELLO_FAIL_COMMAND | 1     |
    And existing environment test-env1
    When I run `rbld help`
    Then the exit status should be 0
    When I run `rbld list`
    Then the exit status should be 100
    When I run `rbld rm test-env1`
    Then the exit status should be 100
    And environment test-env1 should exist
