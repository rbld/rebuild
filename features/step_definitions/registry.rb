Around do |scenario, block|
  registries = [{ :empty        => EmptyDockerRegistry,
                  :populated    => PopulatedDockerRegistry,
                  :unaccessible => UnaccessibleDockerRegistry }]

  registries.each do |registry|
    @registry = registry
    block.call
    break unless @test_all_registries
  end
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
