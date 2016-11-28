module Rebuild::CLI
  class RbldRmCommand < Command
    def initialize
      @usage = "rm [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Remove local environment"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env = Environment.new( parameters[0] )
        rbld_log.info("Going to remove #{env}")
        mgr.remove!( env.full )
      end
    end
  end
end
