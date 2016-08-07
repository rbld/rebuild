Given /^(?:existing )?(?:non\-modified )?(environment #{ENV_NAME_REGEX})$/ do |env|
  env.ensure_exists
  env.ensure_not_modified
end

Given /^(?:existing )?(?:non\-modified )?environments:$/ do |table|
  table.raw.each do |env_name|
    env = RebuildEnvironment.new(env_name[0])
    env.ensure_exists
    env.ensure_not_modified
  end
end

Given /^modified (environment #{ENV_NAME_REGEX})$/ do |env|
  env.ensure_exists
  env.ensure_modified
end

Given /^modified environments:$/ do |table|
  table.raw.each do |env_name|
    env = RebuildEnvironment.new(env_name[0])
    env.ensure_exists
    env.ensure_modified
  end
end

Given /^non-existing (environment #{ENV_NAME_REGEX})$/ do |env|
  env.ensure_does_not_exist
end

Given /^non-existing environments:$/ do |table|
  table.raw.each do |env_name|
    env = RebuildEnvironment.new(env_name[0])
    env.ensure_does_not_exist
  end
end

Then /^(environment #{ENV_NAME_REGEX}) should be marked as modified$/ do |env|
  expect(env.modified?).to be true
end

Then /^(environment #{ENV_NAME_REGEX}) should not be marked as modified$/ do |env|
  expect(env.modified?).to be false
end

Then /^(environment #{ENV_NAME_REGEX}) should be published$/ do |env|
  expect(env.published?).to be true
end

Then /^(environment #{ENV_NAME_REGEX}) should exist$/ do |env|
  expect(env.exists?).to be true
end

Then /^(environment #{ENV_NAME_REGEX}) should not exist$/ do |env|
  expect(env.exists?).to be false
end

Then /^(environment #{ENV_NAME_REGEX}) should be successfully created$/ do |env|
  steps %Q{
    Then the output should contain:
      """
      Successfully created #{env.full_name}
      """
    And the exit status should be 0
  }

  expect(env.exists?).to be true
  expect(env.functional?).to be true
end

Given /^(environment #{ENV_NAME_REGEX}) is modified$/ do |env|
  env.ensure_modified
end

Given /^(environment #{ENV_NAME_REGEX}) is not modified$/ do |env|
  env.ensure_not_modified
end
