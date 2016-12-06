module Rebuild::CLI
  class RbldRmCommand < Command
    def initialize
      @usage = "rm [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Remove local environment"
    end

    def run(parameters)
      env = Environment.new( parameters[0] )
      rbld_log.info("Going to remove #{env}")
      engine_api.remove!( env )
    end
  end
end
