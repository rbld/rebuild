Feature: rbld deploy
  As a CLI user
  I want to be able to deploy environments with rbld deploy

  Scenario: deploy help succeeds and usage is printed
    Given I successfully request help for rbld deploy
    Then help output should contain:
    """
    Deploy environment from remote registry
    """

  Scenario: no remote registry configured
    Given remote registry is not configured
    When I run `rbld deploy some-env:some-tag`
    Then it should fail with:
      """
      ERROR: Remote not defined
      """

    Scenario: remote registry is not accessible
      Given remote registry is not accessible
      When I run `rbld deploy some-env:some-tag`
      Then it should fail with:
        """
        ERROR: Failed to access the registry
        """

    Scenario Outline: deploy environment that does not exist in the registry
    Given my rebuild registry is empty
    When I run `rbld deploy <environment name>`
    Then it should fail with:
      """
      Environment <full environment name> does not exist in the registry
      """

      Examples:
      | environment name    | full environment name |
      | nonexisting         | nonexisting:initial   |
      | nonexisting:sometag | nonexisting:sometag   |

  @slow
  Scenario: deploy a new environment
    Given my rebuild registry contains environment test-env1:v001
    And non-existing environment test-env1:v001
    When I run `rbld deploy test-env1:v001`
    Then it should pass with:
      """
      Successfully deployed test-env1:v001
      """
    And environment test-env1:v001 should exist

  Scenario: deploy already deployed environment
    Given existing environment test-env1:v001
    When I run `rbld deploy test-env1:v001`
    Then it should fail with:
      """
      ERROR: Environment test-env1:v001 already exists
      """
