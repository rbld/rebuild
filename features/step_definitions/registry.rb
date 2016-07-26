Given /^remote registry is not configured$/ do
  rebuild_conf.fill("")
end

Given /^remote registry is not accessible$/ do
  rebuild_conf.set_registry("127.0.0.1:65536")
end

Given /^my rebuild registry is populated with test environments$/ do
  PopulatedTestRegistry.instance.use()
end

Given /^my rebuild registry is empty$/ do
  EmptyTestRegistry.instance.use()
end

Given /^my rebuild registry contains (environment #{ENV_NAME_REGEX})$/ do |env|
  EmptyTestRegistry.instance.use()
  env.EnsureExists
  env.EnsureNotModified
  env.EnsurePublished
end
