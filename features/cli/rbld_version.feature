Feature: rbld version
  As a CLI user
  I want to know version of rebuild I am using

  Scenario: version help succeeds and usage is printed
    Given I successfully request help for rbld version
    Then help output should contain:
    """
    Show the Rebuild version information
    """

  Scenario: rbld version succeeds and version number is printed
    Given I successfully run `rbld version`
    Then it should print version information prefixed by "Rebuild CLI version"
