class RebuildEnvMgr
  def self.list
    env_list = %x(rbld list)
    fail "Failed to list existing environments" unless $?.success?
    return env_list
  end

  def self.checkout(name)
    %x(rbld checkout #{name})
    fail "Failed to checkout #{name}" unless $?.success?
  end

  def self.rm(name)
    %x(rbld rm #{name})
    fail "Failed to delete #{name}" unless $?.success?
  end

  def self.publish(name)
    %x(rbld publish #{name})
    fail "Failed to publish #{name}" unless $?.success?
  end

  def self.status
    modified_list = %x(rbld status)
    fail "Failed to list modified environments" unless $?.success?
    return modified_list
  end

  def self.search
    published_list = %x(rbld search)
    fail "Failed to search for published environments" unless $?.success?
    return published_list
  end

  def self.modify(name)
    %x(rbld modify #{name} -- echo Modifying...)
    fail "Failed to modify #{name}" unless $?.success?
  end

  def self.commit(name, tag)
    %x(rbld commit --tag #{tag} #{name})
    fail "Test environment #{name} commit failed" unless $?.success?
  end

  def self.create(name, base)
    %x(rbld create --base #{base} #{name})
    fail "Failed to create #{name} from #{base}" unless $?.success?
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
