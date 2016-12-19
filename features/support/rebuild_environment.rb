class RebuildEnvMgr
  def self.run_rbld_command(command)
    if ENV['TEST_WORKING_COPY'] == '1'
      rbld = File.expand_path('../../../cli/bin/rbld', __FILE__)
    else
      rbld = 'rbld'
    end

    cmdline = "#{rbld} #{command}"

    output = %x(#{cmdline} 2>&1)
    fail "Failed to run \"#{cmdline}\": #{output}" unless $?.success?
    return output
  end

  private_class_method :run_rbld_command

  def self.list
    run_rbld_command("list")
  end

  def self.checkout(name)
    run_rbld_command("checkout #{name}")
  end

  def self.rm(name)
    run_rbld_command("rm #{name}")
  end

  def self.publish(name)
    run_rbld_command("publish #{name}")
  end

  def self.status
    run_rbld_command("status")
  end

  def self.search
    run_rbld_command("search")
  end

  def self.modify(name)
    run_rbld_command("modify #{name} -- echo Modifying...")
  end

  def self.commit(name, tag)
    run_rbld_command("commit --tag #{tag} #{name}")
  end

  def self.create(name, base)
    run_rbld_command("create --base #{base} #{name}")
  end

  def self.run(name, cmd)
    run_rbld_command("run #{name} -- #{cmd}")
  end

  def self.save_to(name, file)
    run_rbld_command("save #{name} #{file}")
  end

  def self.load_from(file)
    run_rbld_command("load #{file}")
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

  def ensure_exists
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

  def ensure_does_not_exist
    if RebuildEnvMgr.list.include? full_name
      RebuildEnvMgr.checkout full_name
      RebuildEnvMgr.rm full_name
    end
  end

  def modified?
    RebuildEnvMgr.status.include? full_name
  end

  def exists?
    RebuildEnvMgr.list.include? full_name
  end

  def published?
    RebuildEnvMgr.search.include? full_name
  end

  def ensure_modified
    unless modified?
      RebuildEnvMgr.modify full_name
    end
  end

  def ensure_not_modified
    if modified?
      RebuildEnvMgr.checkout full_name
    end
  end

  def ensure_published
    unless published?
      RebuildEnvMgr.publish full_name
    end
  end

  def functional?
    RebuildEnvMgr.run(full_name, 'sudo echo \$HOSTNAME').include? "#{name}-#{tag}"
  end

  def save_to(file_name)
    RebuildEnvMgr.save_to full_name, file_name
  end
end
