Feature: rbld create
  As a CLI user
  I want to be able to create new environments with rbld create

  Background:
    Given non-existing environments:
      | test-env      |
      | test-env:v001 |

  Scenario: create help succeeds and usage is printed
    Given I successfully request help for rbld create
    Then help output should contain "Usage: rbld create [OPTIONS] [ENVIRONMENT]"
    And help output should contain "Create a new environment"
    And help output should match ".*-b.*--base.*Base image from Docker Hub"
    And help output should match ".*-f.*--basefile.*Base file"
    And help output should match ".*--help.*Print usage"

  Scenario: create environment without base
    When I run `rbld create test-env`
    Then it should fail with:
      """
      ERROR: Environment base not specified
      """

  Scenario: create environment with multiple bases
    When I run `rbld create --base base --basefile basefile test-env`
    Then it should fail with:
      """
      ERROR: Exactly one environment base must be specified
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
      Failed to create test-env:initial
      """
    And environment test-env should not exist

  Scenario: create environment from nonexisting file
    When I run `rbld create --basefile nonexisting.file test-env`
    Then it should fail with:
      """
      ERROR: Base file nonexisting.file does not exist
      """
    And environment test-env should not exist

  Scenario Outline: create environment from existing base
    When I run `rbld create <base option> alpine:3.4 test-env`
    Then environment test-env should be successfully created

      Examples:
      |base option|
      |--base     |
      |-b         |

  Scenario: create environment from local docker image
    Given local docker image test_image:latest
    When I run `rbld create --base test_image:latest test-env`
    Then environment test-env should be successfully created

  Scenario Outline: create environment from existing file
    Given existing base file test_base_file.tar
    When I run `rbld create <basefile option> test_base_file.tar test-env`
    Then environment test-env should be successfully created

      Examples:
      |basefile option|
      |--basefile     |
      |-f             |

  Scenario: create environment from existing file outside of current directory
    Given existing base file test_subdir/test_base_file.tar
    When I run `rbld create --basefile test_subdir/test_base_file.tar test-env`
    Then environment test-env should be successfully created

  Scenario: create environment that already exists
    Given existing environment test-env
    When I run `rbld create --base alpine:3.4 test-env`
    Then it should fail with:
      """
      ERROR: Environment test-env:initial already exists
      """
