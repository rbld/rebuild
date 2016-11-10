ENV_NAME_REGEX="[a-zA-Z\\d\\:\\-\\_]+"
Transform /^environment (#{ENV_NAME_REGEX})$/ do |env_name|
  RebuildEnvironment.new(env_name)
end

Transform /^(\d+) times$/ do |i|
  i.to_i
end
