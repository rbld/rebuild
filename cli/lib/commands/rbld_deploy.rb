module Rebuild::CLI
  class RbldDeployCommand < Command
    def initialize
      @usage = "[OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Deploy environment from remote registry"
    end

    def run(parameters)
      env = Environment.new( parameters[0] )
      rbld_log.info("Going to deploy \"#{env}\"")
      engine_api.deploy!( env )
      rbld_print.progress "Successfully deployed #{env}\n"
    end
  end
end
