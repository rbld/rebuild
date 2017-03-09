require 'singleton'
require 'plugman'

class Rebuild::PlugMgr

  include Singleton
  extend Forwardable

  def_delegator :@plugman, :notify

  private

  def initialize
    @plugman = Plugman.new( loader: loader )
    @plugman.load_plugins
  end

  def loader
    ->(a) do
      plugins.each { |p| load( p ) }
    end
  end

  def plugins
    Gem::Specification.\
      map { |g| g.name }.\
      sort.\
      uniq.\
      grep /^rbld-plugin-.*/
    end

  def load(plugin)

    require plugin

    rescue LoadError
      rbld_log.warn( "Failed to load plugin #{plugin}" )
    else
      rbld_log.info( "Loaded plugin #{plugin}" )
  end

end
