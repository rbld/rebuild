Feature: rbld commit
  As a CLI user
  I want to be able to commit environment modifications with rbld commit

  Background:
    Given existing environments:
      | test-env:initial |
      | test-env:v001    |
    And non-existing environment test-env:v002

  Scenario: commit help succeeds and usage is printed
    Given I successfully request help for rbld commit
    Then help output should contain "Commit environment modifications"
    And help output should contain "Usage: rbld commit [OPTIONS] [ENVIRONMENT[:TAG]]"
    And help output should match "-t TAG,--tag TAG.*New tag to be created"
    And help output should match "-h, --help.*Print usage"

  Scenario Outline: commit non-existing environment
    When I run `rbld commit --tag some_new_tag <non-existing environment name>`
    Then it should fail with:
    """
    ERROR: Unknown environment <full environment name>
    """

    Examples:
      | non-existing environment name | full environment name |
      | non-existing                  | non-existing:initial  |
      | non-existing:sometag          | non-existing:sometag  |

  Scenario Outline: commit environment with incorrect tag
    Given environment test-env:v001 is modified
    When I run `rbld commit --tag <incorrect tag name> test-env:v001`
    Then it should fail with:
    """
    ERROR: Invalid new tag (<incorrect tag name>), it may contain lowercase and uppercase letters, digits, underscores, periods and dashes and may not start with a period or a dash.
    """
    And environment test-env:v001 should be marked as modified

    Examples:
      | incorrect tag name |
      | tag$name           |
      | .tagname           |
      | -tagname           |

  Scenario Outline: commit environment with correct tag
    Given environment test-env:v001 is modified
    And non-existing environment test-env:<correct tag name>
    When I run `rbld commit --tag <correct tag name> test-env:v001`
    Then it should pass with:
    """
    Creating new environment test-env:<correct tag name>...
    """
    And environment test-env:v001 should not be marked as modified

    Examples:
      | correct tag name   |
      | tag_name           |
      | tag.name           |
      | tag-name           |
      | _tagname           |
      | tagname_           |
      | tagname-           |
      | tagname.           |
      | tag8name           |
      | a                  |

  Scenario: commit environment which is not modified
    Given environment test-env:v001 is not modified
    When I run `rbld commit --tag v002 test-env:v001`
    Then it should fail with:
    """
    ERROR: No changes to commit for test-env:v001
    """

  Scenario: commit environment which is modified
    Given environment test-env:v001 is modified
    And I run `rbld commit --tag v002 test-env:v001`
    Then it should pass with:
    """
    Creating new environment test-env:v002...
    """
    And environment test-env:v002 should exist
