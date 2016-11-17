Feature: rbld publish
  As a CLI user
  I want to be able to publish environments with rbld publish

  Background:
    Given existing environments:
      | test-env1:initial |
      | test-env1:v001    |
      | test-env2:v001    |

  Scenario: publish help succeeds and usage is printed
    Given I successfully request help for rbld publish
    Then help output should contain:
      """
      Publish environment on remote registry
      """

  Scenario: no remote registry configured
    Given remote registry is not configured
    When I run `rbld publish test-env1:v001`
    Then it should fail with:
      """
      ERROR: Remote not defined
      """

  Scenario Outline: publish environment that does not exist
    Given my rebuild registry is empty
    When I run `rbld publish <environment name>`
    Then it should fail with:
      """
      ERROR: Unknown environment <full environment name>
      """

    Examples:
      | environment name    | full environment name |
      | nonexisting         | nonexisting:initial   |
      | nonexisting:sometag | nonexisting:sometag   |

  Scenario: remote registry is not accessible
    Given remote registry is not accessible
    When I run `rbld publish test-env1:v001`
    Then it should fail with:
      """
      ERROR: Failed to access the registry at
      """

  @slow
  Scenario Outline: publish a new environment
    Given my rebuild registry is empty
    When I run `rbld publish <environment name>`
    Then it should pass with:
      """
      Successfully published <full environment name>
      """
    And environment <environment name> should be published

    Examples:
      | environment name | full environment name |
      | test-env1        | test-env1:initial     |
      | test-env1:v001   | test-env1:v001        |

  Scenario: publish a modified environment
    Given my rebuild registry is empty
    And environment test-env1:v001 is modified
    When I run `rbld publish test-env1:v001`
    Then it should fail with:
      """
      ERROR: Environment is modified, commit or checkout first
      """

  @slow
  Scenario: publish environment which is already published
    Given my rebuild registry contains environment test-env1:v001
    When I run `rbld publish test-env1:v001`
    Then it should fail with:
      """
      ERROR: Environment test-env1:v001 already published
      """
