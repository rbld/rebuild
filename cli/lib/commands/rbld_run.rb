module Rebuild::CLI
  class RbldRunCommand < Command
    def initialize
      @usage = [
                { :syntax => "run [OPTIONS] [ENVIRONMENT[:TAG]]",
                  :description => "Interactive mode: opens shell in the " \
                                  "specified enviroment" },
                { :syntax => "run [OPTIONS] [ENVIRONMENT[:TAG]] -- COMMANDS",
                  :description => "Scripting mode: runs COMMANDS in the " \
                                  "specified environment" }
               ]
      @description = "Run command in a local environment"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env = Environment.new( parameters.shift )
        cmd = get_cmdline_tail( parameters )
        rbld_log.info("Going to run \"#{cmd}\" in \"#{env}\"")
        mgr.run( env.full, cmd )
      end
    end
  end
end
