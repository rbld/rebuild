require 'colorize'

Around do |scenario, block|
  registries = [{ :type         => :docker,
                  :empty        => EmptyDockerRegistry,
                  :populated    => PopulatedDockerRegistry,
                  :unaccessible => UnaccessibleDockerRegistry },
                { :type         => :FS,
                  :empty        => EmptyFSRegistry,
                  :populated    => PopulatedFSRegistry,
                  :unaccessible => UnaccessibleFSRegistry }]

  registries.each do |registry|
    @registry = registry
    block.call
    break unless @test_all_registries
  end
end

After do |scenario|
  if scenario.failed? && @test_all_registries
    puts "== Failed with #{@registry[:type]} registry ==".red
  end
end

at_exit do
  FileUtils.rm_rf(fs_registry_location)
end

Given /^remote registry is not configured$/ do
  rebuild_conf.fill("")
end

Given /^remote registry is not accessible$/ do
  @test_all_registries = true
  @registry[:unaccessible].instance.use()
end

Given /^my rebuild registry is populated with test environments$/ do
  @test_all_registries = true
  @registry[:populated].instance.use()
end

Given /^my rebuild registry is empty$/ do
  @test_all_registries = true
  @registry[:empty].instance.use()
end

Given /^my rebuild registry contains (environment #{ENV_NAME_REGEX})$/ do |env|
  @test_all_registries = true
  @registry[:empty].instance.use()
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
