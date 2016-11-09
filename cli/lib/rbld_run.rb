#!/usr/bin/env ruby

module Rebuild
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
      EnvManager.new do |mgr|
        with_target_name( parameters.shift ) do |fullname|
          cmd = get_cmdline_tail( parameters )
          rbld_log.info("Going to run \"#{cmd}\" in \"#{fullname}\"")
          mgr.run( fullname, cmd )
        end
      end
    end
  end
end
