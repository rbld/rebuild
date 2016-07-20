Feature: rbld create
  As a CLI user
  I want to be able to create new environments with rbld create

  Background:
    Given non-existing environment test-env
    Given non-existing environment test-env:v001

  Scenario: create help exit status of 0
    When I run `rbld create --help`
    Then the exit status should be 0

  Scenario: create help header is printed
    Given I successfully run `rbld create --help`
    Then the output should contain:
      """
      Create a new environment
      """

  Scenario: create environment without base
    When I run `rbld create test-env`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Environment base not specified
      """

  Scenario: create environment with tag
    When I run `rbld create --base fedora:20 test-env:v001`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Environment tag must not be specified
      """

  Scenario: create environment with incorrect name
    When I run `rbld create --base fedora:20 incorrect~name`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Invalid environment name (incorrect~name), it may contain a-z, A-Z, 0-9, - and _ characters only
      """

  Scenario: create environment from nonexisting base
    When I run `rbld create --base nonexisting:nonexisting test-env`
    Then the exit status should not be 0
    And the output should contain:
      """
      ERROR: Failed to download base image nonexisting:nonexisting
      """
    And environment test-env should not exist

  Scenario: create environment from existing base
    When I successfully run `rbld create --base fedora:20 test-env`
    Then the output should contain:
      """
      Successfully created test-env:initial
      """
    And environment test-env should exist

  Scenario: create environment that already exists
    Given existing environment test-env
    When I run `rbld create --base fedora:20 test-env`
    Then the exit status should not be 0
    Then the output should contain:
      """
      ERROR: Environment test-env:initial already exists
      """
