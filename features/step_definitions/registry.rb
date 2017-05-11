require 'colorize'

After('@with-registry') do |scenario|
  if scenario.failed?
    STDERR.puts "== Failed with #{registry_type} registry ==".red
  end
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

def fill_rebuild_conf
  rebuild_conf.fill %Q{
    REMOTE_NAME=origin
    REMOTE_TYPE_origin="#{@reg_type}"
    REMOTE_origin="#{@reg_path}"
  }
end

Given(/^remote registry type is "([^"]*)"$/) do |type|
  @reg_type = type
  @reg_path ||= "__#{type}__path__"
  fill_rebuild_conf
end

Given(/^remote registry path is "([^"]*)"$/) do |path|
  @reg_type ||= 'rebuild'
  @reg_path = path
  fill_rebuild_conf
end
