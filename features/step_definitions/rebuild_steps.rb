Given(/^existing environment ([a-zA-Z\d\:\-\_]+)$/) do |env|
  EnsureTestEnvironmentExists(env)
  EnsureTestEnvironmentIsNotModified(env)
end

Given(/^non-existing environment ([a-zA-Z\d\:\-\_]+)$/) do |env|
  EnsureTestEnvironmentDoesNotExist(env)
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should be marked as modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  expect(EnvironmentIsModified?(fullname)).to be true
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should not be marked as modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  expect(EnvironmentIsModified?(fullname)).to be false
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should exist$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  steps %Q{
    When I successfully run `rbld list`
    Then the output should contain:
      """
      #{fullname}
      """
  }
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should not exist$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  steps %Q{
    When I successfully run `rbld list`
    Then the output should not contain:
      """
      #{fullname}
      """
  }
end

Given(/^environment ([a-zA-Z\d\:\-\_]+) is modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  unless EnvironmentIsModified?(fullname)
    %x(rbld modify #{fullname} -- echo Modifying...)
    raise("Test environment #{fullname} modification failed") unless $?.success?
  end
end

Given(/^environment ([a-zA-Z\d\:\-\_]+) is not modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  if EnvironmentIsModified?(fullname)
    %x(rbld checkout #{fullname})
    raise("Test environment #{fullname} checkout failed") unless $?.success?
  end
end

Then(/^the output should be empty$/) do
  steps %Q{
    Then the output should contain exactly:
      """
      """
  }
end

def FillConfigFile(content)
  cfg_file = GetCfgFilePathName();

  %x(sudo tee #{cfg_file}<<END
#{content}
END)

  raise("Configuration file #{cfg_file} population failed") unless $?.success?
end

Given(/^remote registry is not configured$/) do
  FillConfigFile ""
end

Given(/^remote registry is not accessible$/) do
  UseRegistry("127.0.0.1:65536")
end

Given(/^configured remote registry is (.+)$/) do |url|
  UseRegistry(url)
end

Given /^my rebuild registry is populated with test environments$/ do
  PopulatedTestRegistry.instance.use()
end

Given /^my rebuild registry is empty$/ do
  CleanTestRegistry.instance.use()
end
