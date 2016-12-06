module Rebuild::CLI
  class RbldModifyCommand < Command
    def initialize
      @usage = [
                { :syntax => "modify [OPTIONS] [ENVIRONMENT[:TAG]]",
                  :description => "Interactive mode: opens shell in the " \
                                  "specified enviroment" },
                { :syntax => "modify [OPTIONS] [ENVIRONMENT[:TAG]] -- COMMANDS",
                  :description => "Scripting mode: runs COMMANDS in the " \
                                  "specified environment" }
               ]
      @description = "Modify a local environment"
    end

    def run(parameters)
      env = Environment.new( parameters.shift )
      cmd = get_cmdline_tail( parameters )
      rbld_log.info("Going to modify \"#{env}\" with \"#{cmd}\"")
      engine_api.modify!( env, cmd )
    end
  end
end
