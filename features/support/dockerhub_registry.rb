require 'singleton'
require 'securerandom'

require_relative 'dockerhub'

class BaseDockerHubRegistry
  private

  def cred(name)
    ENV["RBLD_CREDENTIAL_#{name.upcase}"]
  end

  def create_registry
    @registry_path = "#{@registry_base}-#{SecureRandom.uuid}"
    @dockerhub_repos << @registry_path
    @rebuild_conf.set_registry(:dockerhub,  @registry_path)
  end

  def recreate_registry
    create_registry
  end

  public

  def initialize(name)
    @registry_base = "#{dockerhub_namespace}/ci-#{name}"
    @rebuild_conf = RebuildConfFile.new

    @dockerhub_repos = []
    at_exit do
      puts
      puts "Running post-test cleanups:"
      dh = Rebuild::DockerHub.new(cred('username'), cred('password'))
      dh.kill_repos(@dockerhub_repos)
    end

    create_registry
  end

  def populate_registry
    ["1:v001", "1:v002", "2:v001"].each do |suffix|
      env = RebuildEnvironment.new("test-env#{suffix}")
      env.ensure_exists
      env.ensure_not_modified
      env.ensure_published
    end
  end

  def use
    @rebuild_conf.set_registry(:dockerhub,  @registry_path)
  end
end

class UnaccessibleDockerHubRegistry
  include Singleton

  def use
    RebuildConfFile.new.set_registry(:dockerhub, 'rbld-no-namespace/rbld-no-repo')
    yield 'RBLD_OVERRIDE_INDEX_ENDPOINT', 'unaccessible.rbld.io'
  end
end

class PopulatedDockerHubRegistry < BaseDockerHubRegistry
  include Singleton

  def initialize
    super('populated')
    populate_registry()
  end
end

class EmptyDockerHubRegistry < BaseDockerHubRegistry
  include Singleton

  def initialize
    super('empty')
  end

  def use
    recreate_registry
    super
  end
end
