Given(/^existing environment ([a-zA-Z\d\:\-\_]+)$/) do |env|
  default_tag="initial"

  name, tag = env.split(/:/)

  if tag.to_s.empty?
    tag=default_tag
  end

  env_list = %x(rbld list)

  unless env_list.include? name + ":" + tag

    unless env_list.include? name + ":" + default_tag
      %x(rbld create --base fedora:20 #{name})
      raise("Test environment #{name} creation failed") unless $?.success?
    end

    unless tag == default_tag
      %x(rbld modify #{name} -- echo "Modifying the environment")
      raise("Test environment #{name} modification failed") unless $?.success?

      %x(rbld commit --tag #{tag} #{name})
      raise("Test environment #{name}:#{tag} commit failed") unless $?.success?
    end

  end


end
