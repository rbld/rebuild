@community
Feature: environments for commonly used platforms
  As a rebuild community participant
  I want access to precreated environments for commonly used platforms

  Background:
    Given I use default rbld CLI configuration
    Given sample source code from "cli/tests/hello"

  Scenario: there are pre-created environments on Docker Hub
    When I successfully run `rbld search`
    Then the output should contain "Searching in rbld/environments..."
    And the output should contain "bb-x15:16-05"
    And the output should contain "rpi-raspbian:v001"

  Scenario Outline: test pre-created environments that can build stand-alone applications
    Given non-existing environment <environment name>
    When I successfully run `rbld deploy <environment name>`
    And I cd to "hello"
    And I successfully run `rbld run <environment name> -- make`
    Then the file "hello" should exist

    Examples:
      | environment name        |
      | bb-x15:16-05            |
      | rpi-raspbian:v001       |

  Scenario Outline: test pre-created environments that cannot build stand-alone applications
    Given non-existing environment <environment name>
    When I successfully run `rbld deploy <environment name>`
    And I run `rbld run <environment name> -- exit 5`
    Then the exit status should be 5
    When I run `rbld run <environment name> -- exit 0`
    Then the exit status should be 0

    Examples:
      | environment name        |
      | nrf5:13                 |
      | qiskit:r0.3             |
