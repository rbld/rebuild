module Rebuild::CLI
  class RbldCheckoutCommand < Command
    def initialize
      @usage = "checkout [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Discard environment modifications"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env = Environment.new( parameters[0] )
        rbld_log.info("Going to checkout #{env}")
        mgr.checkout!(env.full, env.name, env.tag)
      end
    end
  end
end
