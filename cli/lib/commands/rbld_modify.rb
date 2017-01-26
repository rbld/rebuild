module Rebuild::CLI
  class RbldModifyCommand < Command

    include RunOptions

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
      @options = [["-p, --privileged", "Run environment with superuser privileges"]]
    end

    def run(parameters)
      runopts, parameters = parse_opts( parameters )
      env = Environment.new( parameters.shift )
      cmd = get_cmdline_tail( parameters )
      rbld_log.info("Going to modify \"#{env}\" with \"#{cmd}\"")
      @errno = engine_api.modify!( env, cmd, runopts )
    end
  end
end
