Feature: rbld create
  As a CLI user
  I want to be able to create new environments with rbld create

  Background:
    Given non-existing environments:
      | test-env      |
      | test-env:v001 |

  Scenario: create help succeeds and usage is printed
    Given I run `rbld create --help`
    Then the output should match:
    """
    Create a new environment
    .*-b.*--base.*
    .*--help.*
    """
    And the exit status should be 0

  Scenario: create environment without base
    When I run `rbld create test-env`
    Then it should fail with:
      """
      ERROR: Environment base not specified
      """

  Scenario: create environment with tag
    When I run `rbld create --base alpine:3.4 test-env:v001`
    Then it should fail with:
      """
      ERROR: Environment tag must not be specified
      """

  Scenario: create environment with incorrect name
    When I run `rbld create --base alpine:3.4 incorrect~name`
    Then it should fail with:
      """
      ERROR: Invalid environment name (incorrect~name), it may contain a-z, A-Z, 0-9, - and _ characters only
      """

  Scenario: create environment from nonexisting base
    When I run `rbld create --base nonexisting:nonexisting test-env`
    Then it should fail with:
      """
      ERROR: Failed to download base image nonexisting:nonexisting
      """
    And environment test-env should not exist

  Scenario: create environment from existing base
    When I run `rbld create --base alpine:3.4 test-env`
    Then the output should contain:
      """
      Successfully created test-env:initial
      """
    And the exit status should be 0
    And environment test-env should exist

  Scenario: create environment that already exists
    Given existing environment test-env
    When I run `rbld create --base alpine:3.4 test-env`
    Then it should fail with:
      """
      ERROR: Environment test-env:initial already exists
      """
