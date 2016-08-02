class RebuildEnvMgr
  def self.run_command(command)
    output = %x(#{command} 2>&1)
    fail "Failed to run \"#{command}\": #{output}" unless $?.success?
    return output
  end

  private_class_method :run_command

  def self.list
    run_command("rbld list")
  end

  def self.checkout(name)
    run_command("rbld checkout #{name}")
  end

  def self.rm(name)
    run_command("rbld rm #{name}")
  end

  def self.publish(name)
    run_command("rbld publish #{name}")
  end

  def self.status
    run_command("rbld status")
  end

  def self.search
    run_command("rbld search")
  end

  def self.modify(name)
    run_command("rbld modify #{name} -- echo Modifying...")
  end

  def self.commit(name, tag)
    run_command("rbld commit --tag #{tag} #{name}")
  end

  def self.create(name, base)
    run_command("rbld create --base #{base} #{name}")
  end
end

class RebuildEnvironment
  DEFAULT_TAG="initial"
  private_constant :DEFAULT_TAG

  def initialize(name)
    @name, @tag = name.split(/:/)
    @tag=DEFAULT_TAG if @tag.to_s.empty?
  end

  attr_reader :name
  attr_reader :tag

  def full_name
    "#{@name}:#{@tag}"
  end

  def initial_name
    "#{name}:#{DEFAULT_TAG}"
  end

  def EnsureExists
    env_list = RebuildEnvMgr.list

    unless env_list.include? full_name

      unless env_list.include? name + ":" + DEFAULT_TAG
        RebuildEnvMgr.create name, test_env_base
      end

      unless tag == DEFAULT_TAG
        RebuildEnvMgr.modify initial_name
        RebuildEnvMgr.commit initial_name,tag
      end

    end
  end

  def EnsureDoesNotExist
    if RebuildEnvMgr.list.include? full_name
      RebuildEnvMgr.checkout full_name
      RebuildEnvMgr.rm full_name
    end
  end

  def Modified?
    RebuildEnvMgr.status.include? full_name
  end

  def Exists?
    RebuildEnvMgr.list.include? full_name
  end

  def Published?
    RebuildEnvMgr.search.include? full_name
  end

  def EnsureModified
    unless Modified?
      RebuildEnvMgr.modify full_name
    end
  end

  def EnsureNotModified
    if Modified?
      RebuildEnvMgr.checkout full_name
    end
  end

  def EnsurePublished
    unless Published?
      RebuildEnvMgr.publish full_name
    end
  end
end
