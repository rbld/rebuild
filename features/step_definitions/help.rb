Given(/^I successfully request help for rbld (.*)$/) do |rbld_cmd|
  @rbld_cmd = rbld_cmd
end

Then(/^help output should contain:$/) do |string|
  steps %Q{
    Given I run `rbld #{@rbld_cmd} --help`
    Then it should pass with:
    """
    #{string}
    """

    Given I run `rbld help #{@rbld_cmd}`
    Then it should pass with:
    """
    #{string}
    """
  }
end

Then(/^help output should match:$/) do |regex|
  steps %Q{
    Given I successfully run `rbld #{@rbld_cmd} --help`
    Then the output should match:
    """
    #{regex}
    """

    Given I successfully run `rbld help #{@rbld_cmd}`
    Then the output should match:
    """
    #{regex}
    """
  }
end
