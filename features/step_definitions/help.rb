Given(/^I( successfully)? request help for rbld (.*)$/) do |check_status, rbld_cmd|
  @outputs  = []

  [ "help #{rbld_cmd}",
    "#{rbld_cmd} -h",
    "#{rbld_cmd} --help" ].each do |cmd|
      output = %x(rbld #{cmd})
      @outputs << [output, $?]
      expect($?).to be == 0 if check_status
  end
end

def expect_help_to_include(string)
  @outputs.each { |output| expect(output[0]).to include(string) }
end

def expect_help_to_match(regex)
  @outputs.each { |output| expect(output[0]).to match(regex) }
end

def expect_help_exit_status(status)
  @outputs.each { |output| expect(output[1]).to be == status }
end

Then(/^help output should (contain|match):$/) do |option, string|
  option == 'contain' ? expect_help_to_include(string)
                      : expect_help_to_match(string)
end

Then(/^help output should (contain|match) "([^"]*)"$/) do |option, string|
  option == 'contain' ? expect_help_to_include(string)
                      : expect_help_to_match(string)
end

Then(/^the command help screen should be presented successfully$/) do
  expect_help_exit_status(0)
end
