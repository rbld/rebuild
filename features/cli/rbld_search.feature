Feature: rbld search
  As a CLI user
  I want to be able to search for published environments with rbld search

  Scenario: search help succeeds and usage is printed
    Given I run `rbld search --help`
    Then it should pass with:
      """
      Search remote registry for published environments
      """

  Scenario: no remote registry configured
    Given remote registry is not configured
    When I run `rbld search`
    Then it should fail with:
      """
      ERROR: Remote not defined
      """

  Scenario: remote registry is not accessible
    Given remote registry is not accessible
    When I run `rbld search`
    Then it should fail with:
      """
      ERROR: Failed to search in
      """

  Scenario Outline: search matching functionality
    Given my rebuild registry is <registry contents>
    When I run `rbld search <wildcard>`
    Then it should pass with:
      """
      Searching in
      """
    And the output <should or should not contain>:
      """
      <text>
      """

    Examples: Empty registry
      | registry contents                | wildcard       | should or should not contain | text           |
      | empty                            |                | should not contain           | test-env       |

    @slow
    Examples: Populated registry

      We expect that following environments are published:
         test-env1:v001
         test-env1:v002
         test-env2:v001

      | registry contents                | wildcard       | should or should not contain | text            |
      | populated with test environments |                | should contain               | test-env1:v001  |
      | populated with test environments |                | should contain               | test-env1:v002  |
      | populated with test environments |                | should contain               | test-env2:v001  |
      | populated with test environments | test-env       | should contain               | test-env1:v001  |
      | populated with test environments | test-env       | should contain               | test-env1:v002  |
      | populated with test environments | test-env       | should contain               | test-env2:v001  |
      | populated with test environments | test-env1      | should contain               | test-env1:v001  |
      | populated with test environments | test-env1      | should contain               | test-env1:v002  |
      | populated with test environments | test-env1      | should not contain           | test-env2       |
      | populated with test environments | test-env1:v001 | should contain               | test-env1:v001  |
      | populated with test environments | test-env1:v001 | should not contain           | test-env1:v002  |
      | populated with test environments | test-env1:v001 | should not contain           | test-env2       |
      | populated with test environments | nonexisting    | should not contain           | test-env        |
