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
      env = Environment.new( parameters.shift )
      cmd = get_cmdline_tail( parameters )
      rbld_log.info("Going to run \"#{cmd}\" in \"#{env}\"")

      warn_if_modified( env, 'running' )
      engine_api.run( env, cmd )
    end
  end
end
