require 'singleton'
require 'docker_registry2'

class BaseTestRegistry
  REGISTRY_BASE="rbld_populated_test_registry"
  REGISTRY_HOST="127.0.0.1"
  private_constant :REGISTRY_BASE, :REGISTRY_HOST

  private

  def registry_connect!
    DockerRegistry.connect("http://#{REGISTRY_HOST}:#{@registry_port}")
  end

  public

  def initialize
    @registry_port=0
    @registry_name="non_existing_rbld_test_container"
    @rebuild_conf=RebuildConfFile.new
    create_registry
  end

  def kill_registry
    if %x(docker ps -a).include? @registry_name
      %x(docker rm -f #{@registry_name})
      fail "Failed to kill container #{@registry_name}" unless $?.success?
    end
  end

  def create_registry
    run_registry()
    @rebuild_conf.set_registry("#{REGISTRY_HOST}:#{@registry_port}")
  end

  def run_registry_container
    for @registry_port in 5001..20000
      @registry_name = "#{REGISTRY_BASE}_#{@registry_port}"

      output = %x(docker run -d -p #{@registry_port}:5000 --name #{@registry_name} #{registry_image_name} 2>&1)
      return if $?.success?

      next if output.include? "is already in use by container"

      kill_registry

      break unless output.include? "address already in use" or output.include? "port is already allocated"
    end

    fail "Failed to run container #{@registry_name}"

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
          registry_connect!
      end

    end
  end

  def populate_registry
    ["1:v001", "1:v002", "2:v001"].each do |suffix|
      env = RebuildEnvironment.new("test-env#{suffix}")
      env.ensure_exists
      env.ensure_not_modified
      env.ensure_published
    end
  end

  def empty?
    registry_connect!.search.empty?
  end

  def use
    @rebuild_conf.set_registry("#{REGISTRY_HOST}:#{@registry_port}")
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

class EmptyTestRegistry < BaseTestRegistry
  include Singleton

  def initialize
    super
    at_exit { EmptyTestRegistry.instance.kill_registry }
  end

  def use
    unless empty?
      kill_registry
      initialize
    end

    super
  end
end
