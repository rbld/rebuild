require 'colorize'

After('@with-registry') do |scenario|
  if scenario.failed?
    STDERR.puts "== Failed with #{registry_type} registry ==".red
  end
end

at_exit do
  FileUtils.rm_rf(fs_registry_location)
end

Given /^remote registry is not configured$/ do
  rebuild_conf.fill("")
end

Given /^remote registry is not accessible$/ do
  registry_classes[:unaccessible].instance.use() do |var, val|
    set_environment_variable(var, val)
  end
end

Given /^my rebuild registry is populated with test environments$/ do
  registry_classes[:populated].instance.use()
end

Given /^my rebuild registry is empty$/ do
  registry_classes[:empty].instance.use()
end

Given /^my rebuild registry contains (environment #{ENV_NAME_REGEX})$/ do |env|
  registry_classes[:empty].instance.use()
  env.ensure_exists
  env.ensure_not_modified
  env.ensure_published
end

Given(/^remote registry type is "([^"]*)"$/) do |type|
  rebuild_conf.fill %Q{
    REMOTE_NAME=origin
    REMOTE_TYPE_origin="#{type}"
    REMOTE_origin="__#{type}__path__"
  }
end
