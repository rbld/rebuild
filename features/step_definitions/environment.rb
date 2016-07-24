Given /^existing (environment #{ENV_NAME_REGEX})$/ do |env|
  env.EnsureExists
  env.EnsureNotModified
end

Given /^non-existing (environment #{ENV_NAME_REGEX})$/ do |env|
  env.EnsureDoesNotExist
end

Then /^(environment #{ENV_NAME_REGEX}) should be marked as modified$/ do |env|
  expect(env.Modified?).to be true
end

Then /^(environment #{ENV_NAME_REGEX}) should not be marked as modified$/ do |env|
  expect(env.Modified?).to be false
end

Then /^(environment #{ENV_NAME_REGEX}) should exist$/ do |env|
  expect(env.Exists?).to be true
end

Then /^(environment #{ENV_NAME_REGEX}) should not exist$/ do |env|
  expect(env.Exists?).to be false
end

Given /^(environment #{ENV_NAME_REGEX}) is modified$/ do |env|
  env.EnsureModified
end

Given /^(environment #{ENV_NAME_REGEX}) is not modified$/ do |env|
  env.EnsureNotModified
end
