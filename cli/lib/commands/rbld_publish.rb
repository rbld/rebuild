module Rebuild::CLI
  class RbldPublishCommand < Command
    def initialize
      @usage = "publish [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Publish environment on remote registry"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env = Environment.new( parameters[0] )
        rbld_log.info("Going to publish \"#{env}\"")
        mgr.publish( env.full, env.name, env.tag )
      end
    end
  end
end
