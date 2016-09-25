Feature: rbld
  As a CLI user
  I want to be notified when I try to run an unknown command

  Scenario: rbld _unknown_command_ fails with error
    Given I run `rbld _unknown_command_`
    Then it should fail with:
    """
    ERROR: Unknown command: _unknown_command_
    """
