require 'aruba/cucumber'

Aruba.configure do |config|
  config.exit_timeout = 600
end

def GetCfgFilePathName()
  require 'ptools'
  require 'pathname'

  rbld_path = File.which("rbld")
  raise('Failed to find rbld executable') if rbld_path.to_s.empty?

  return Pathname(rbld_path).dirname().to_path() + "/../etc/rebuild.conf"
end

Before do
  cfg_file=GetCfgFilePathName()
  cfg_file_backup=cfg_file + ".backup"
  %x(sudo cp -p #{cfg_file} #{cfg_file_backup})
  raise("Failed to backup config file #{cfg_file} -> #{cfg_file_backup}") unless $?.success?
end

After do
  cfg_file=GetCfgFilePathName()
  cfg_file_backup=cfg_file + ".backup"
  %x(sudo mv #{cfg_file_backup} #{cfg_file})
  raise("Failed to restore config file #{cfg_file_backup} -> #{cfg_file}") unless $?.success?
end

$default_tag="initial"

def NormalizeEnvName(env)
  name, tag = env.split(/:/)
  if tag.to_s.empty?
    tag=$default_tag
  end
  fullname=name + ":" + tag

  return name, tag, fullname
end

def EnsureTestEnvironmentExists(env_name)
  name, tag, fullname = NormalizeEnvName(env_name)
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
end

def EnsureTestEnvironmentDoesNotExist(env_name)
  name, tag, fullname = NormalizeEnvName(env_name)
  env_list = %x(rbld list)

  if env_list.include? fullname
    %x(rbld checkout #{fullname})
    raise("Test environment #{fullname} checkout failed") unless $?.success?
    %x(rbld rm #{fullname})
    raise("Test environment #{fullname} deletion failed") unless $?.success?
  end
end

def EnvironmentIsModified?(fullname)
  return %x(rbld status).include? fullname
end

def EnsureTestEnvironmentIsNotModified(env_name)
  name, tag, fullname = NormalizeEnvName(env_name)

  if EnvironmentIsModified? fullname
    %x(rbld checkout #{fullname})
    raise("Test environment #{fullname} checkout failed") unless $?.success?
  end
end

def EnsureTestEnvironmentIsPublished(env_name)
  name, tag, fullname = NormalizeEnvName(env_name)
  published_list=%x(rbld search)

  unless published_list.include? fullname
    %x(rbld publish #{fullname})
    raise("Failed to publish test environment #{fullname}") unless $?.success?
  end
end

def FillConfigFile(content)
  cfg_file = GetCfgFilePathName();

  %x(sudo tee #{cfg_file}<<END
#{content}
END)

  raise("Configuration file #{cfg_file} population failed") unless $?.success?
end

def UseRegistry(url)
  FillConfigFile %Q{
      REMOTE_NAME=origin
      REMOTE_origin="#{url}"
  }
end

$rbld_populated_registry_created = false
$rbld_populated_registry_name = "rbld_populated_test_registry"

require 'singleton'

class BaseTestRegistry
  REGISTRY_BASE="rbld_populated_test_registry"
  REGISTRY_HOST="127.0.0.1"
  private_constant :REGISTRY_BASE, :REGISTRY_HOST

  def initialize
    @registry_port=0
    @registry_name="non_existing_rbld_test_container"
    create_registry
  end

  def kill_registry
    if %x(docker ps -a).include? @registry_name
      %x(docker rm -f #{@registry_name})
      raise("Failed to kill container #{@registry_name}") unless $?.success?
    end
  end

  def create_registry
    run_registry()
    UseRegistry("#{REGISTRY_HOST}:#{@registry_port}")
  end

  def run_registry_container
    for @registry_port in 5001..20000
      @registry_name = "#{REGISTRY_BASE}_#{@registry_port}"

      output = %x(docker run -d -p #{@registry_port}:5000 --name #{@registry_name} registry 2>&1)
      return if $?.success?

      next if output.include? "is already in use by container"

      kill_registry

      break unless output.include? "address already in use" or output.include? "port is already allocated"
    end

    raise("Failed to run container #{@registry_name}")

  end

  def run_registry
    require 'retriable'

    # Run registry container a and wait for it to start
    # Sometimes it just fails to start so we're trying a few times
    kill_registry_on_retry = Proc.new do
      kill_registry
    end

    Retriable.retriable intervals: Array.new(5, 0), on_retry: kill_registry_on_retry do

      run_registry_container

      Retriable.retriable intervals: Array.new(20, 1) do
          %x{docker search '#{REGISTRY_HOST}:#{@registry_port}/*' 2>&1}
          raise("Failed to connect to created registry") unless $?.success?
      end

    end
  end

  def populate_registry
    ["1:v001", "1:v002", "2:v001"].each do |suffix|
      name="test-env#{suffix}"
      EnsureTestEnvironmentExists(name)
      EnsureTestEnvironmentIsNotModified(name)
      EnsureTestEnvironmentIsPublished(name)
    end
  end

  def use()
    UseRegistry("#{REGISTRY_HOST}:#{@registry_port}")
  end
end

class PopulatedTestRegistry < BaseTestRegistry
  include Singleton

  def initialize
    super
    at_exit { PopulatedTestRegistry.instance.kill_registry }
    populate_registry()
  end
end

class CleanTestRegistry < BaseTestRegistry
  include Singleton

  def initialize
    super
    at_exit { CleanTestRegistry.instance.kill_registry }
  end
end
