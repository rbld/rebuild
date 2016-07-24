Given(/^existing (environment #{ENV_NAME_REGEX})$/) do |env|
  env.EnsureExists
  env.EnsureNotModified
end

Given(/^non-existing (environment #{ENV_NAME_REGEX})$/) do |env|
  env.EnsureDoesNotExist
end

Then(/^(environment #{ENV_NAME_REGEX}) should be marked as modified$/) do |env|
  expect(env.Modified?).to be true
end

Then(/^(environment #{ENV_NAME_REGEX}) should not be marked as modified$/) do |env|
  expect(env.Modified?).to be false
end

Then(/^(environment #{ENV_NAME_REGEX}) should exist$/) do |env|
  expect(env.Exists?).to be true
end

Then(/^(environment #{ENV_NAME_REGEX}) should not exist$/) do |env|
  expect(env.Exists?).to be false
end

Given(/^(environment #{ENV_NAME_REGEX}) is modified$/) do |env|
  env.EnsureModified
end

Given(/^(environment #{ENV_NAME_REGEX}) is not modified$/) do |env|
  env.EnsureNotModified
end

Then(/^the output should be empty$/) do
  steps %Q{
    Then the output should contain exactly:
      """
      """
  }
end

Given(/^remote registry is not configured$/) do
  rebuild_conf.fill("")
end

Given(/^remote registry is not accessible$/) do
  rebuild_conf.set_registry("127.0.0.1:65536")
end

Given /^my rebuild registry is populated with test environments$/ do
  PopulatedTestRegistry.instance.use()
end

Given /^my rebuild registry is empty$/ do
  CleanTestRegistry.instance.use()
end
