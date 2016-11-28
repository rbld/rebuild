module Rebuild::CLI
  class RbldDeployCommand < Command
    def initialize
      @usage = "deploy [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Deploy environment from remote registry"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env = Environment.new( parameters[0] )
        cmd = get_cmdline_tail( parameters )
        rbld_log.info("Going to deploy \"#{env}\"")
        mgr.deploy!( env.full, env.name, env.tag )
      end
    end
  end
end
