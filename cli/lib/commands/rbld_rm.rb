module Rebuild::CLI
  class RbldRmCommand < Command
    def initialize
      @usage = "[OPTIONS] [ENVIRONMENT[:TAG]]..."
      @description = "Remove one or more local environments"
    end

    def run(parameters)
      raise EnvironmentNameEmpty unless parameters.any?
      parameters.each do |parameter|
        env = Environment.new( parameter )
        rbld_log.info("Going to remove #{env}")
        engine_api.remove!( env )
      end
    end
  end
end
