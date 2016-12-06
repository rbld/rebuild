module Rebuild::CLI
  class RbldCheckoutCommand < Command
    def initialize
      @usage = "checkout [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Discard environment modifications"
    end

    def run(parameters)
      env = Environment.new( parameters[0] )
      rbld_log.info("Going to checkout #{env}")
      engine_api.checkout!( env )
    end
  end
end
