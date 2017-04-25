module Rebuild::CLI
  class RbldRunCommand < Command

    include RunOptions

    def initialize
      @usage = [
                { :syntax => "[OPTIONS] [ENVIRONMENT[:TAG]]",
                  :description => "Interactive mode: opens shell in the " \
                                  "specified enviroment" },
                { :syntax => "[OPTIONS] [ENVIRONMENT[:TAG]] -- COMMANDS",
                  :description => "Scripting mode: runs COMMANDS in the " \
                                  "specified environment" }
               ]
      @description = "Run command in a local environment"
      @options = opts_text
    end

    def run(parameters)
      runopts, parameters = parse_opts( parameters )
      env = Environment.new( parameters.shift )
      cmd = get_cmdline_tail( parameters )
      rbld_log.info("Going to run \"#{cmd}\" in \"#{env}\"")

      warn_if_modified( env, 'running' )
      @errno = engine_api.run( env, cmd, runopts )
    end
  end
end
