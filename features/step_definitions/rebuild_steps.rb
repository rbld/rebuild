$default_tag="initial"

def NormalizeEnvName(env)
  name, tag = env.split(/:/)
  if tag.to_s.empty?
    tag=$default_tag
  end
  fullname=name + ":" + tag

  return name, tag, fullname
end

def EnvironmentIsModified?(fullname)
  return %x(rbld status).include? fullname
end

Given(/^existing environment ([a-zA-Z\d\:\-\_]+)$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  env_list = %x(rbld list)

  unless env_list.include? fullname

    unless env_list.include? name + ":" + $default_tag
      %x(rbld create --base fedora:20 #{name})
      raise("Test environment #{name} creation failed") unless $?.success?
    end

    unless tag == $default_tag
      %x(rbld modify #{name} -- echo "Modifying the environment")
      raise("Test environment #{name} modification failed") unless $?.success?

      %x(rbld commit --tag #{tag} #{name})
      raise("Test environment #{fullname} commit failed") unless $?.success?
    end

  end

  if EnvironmentIsModified? fullname
    %x(rbld checkout #{fullname})
    raise("Test environment #{fullname} checkout failed") unless $?.success?
  end
end

Then(/^environment ([a-zA-Z\d\:\-\_]+) should be marked as modified$/) do |env|
  name, tag, fullname = NormalizeEnvName(env)
  expect(EnvironmentIsModified?(fullname)).to be true
end
