module Rebuild::CLI
  class RbldPublishCommand < Command
    def initialize
      @usage = "publish [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Publish environment on remote registry"
    end

    def run(parameters)
      env = Environment.new( parameters[0] )
      rbld_log.info("Going to publish \"#{env}\"")
      engine_api.publish( env )
      rbld_print.progress "Successfully published #{env}\n"
    end
  end
end
