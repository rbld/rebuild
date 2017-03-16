@community
Feature: environments for commonly used platforms
  As a rebuild community participant
  I want access to precreated environments for commonly used platforms

  Background:
    Given sample source code from "cli/tests/hello"

  Scenario: there are pre-created environments on Docker Hub
    When I successfully run `rbld search`
    Then the output should contain "Searching in rbld/environments..."
    And the output should contain "bb-x15:16-05"
    And the output should contain "rpi-raspbian:v001"

  Scenario Outline: deploy pre-created environments from Docker Hub
    Given non-existing environment <environment name>
    When I successfully run `rbld deploy <environment name>`
    And I cd to "hello"
    And I successfully run `rbld run <environment name> -- make`
    Then the file "hello" should exist

    Examples:
      | environment name        |
      | bb-x15:16-05            |
      | rpi-raspbian:v001       |
