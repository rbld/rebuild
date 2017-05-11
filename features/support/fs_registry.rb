require 'singleton'

class BaseFSRegistry
  private

  def recreate_registry
    FileUtils.rm_rf(@registry_path)
    FileUtils.mkdir_p(@registry_path)
    @rebuild_conf.set_registry(:rebuild,  @registry_path)
  end

  public

  def initialize(dirname)
    @registry_path = File.join(fs_registry_location, dirname)
    @rebuild_conf = RebuildConfFile.new
    recreate_registry
    at_exit { FileUtils.rm_rf(fs_registry_location) }
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
    @rebuild_conf.set_registry(:rebuild,  @registry_path)
  end
end

class UnaccessibleFSRegistry
  include Singleton

  def use
    RebuildConfFile.new.set_registry(:rebuild, '/non/existing/path')
  end
end

class PopulatedFSRegistry < BaseFSRegistry
  include Singleton

  def initialize
    super('rbld_populated_fs_test_registry')
    populate_registry()
  end
end

class EmptyFSRegistry < BaseFSRegistry
  include Singleton

  def initialize
    super('rbld_empty_fs_test_registry')
  end

  def use
    recreate_registry
    super
  end
end
