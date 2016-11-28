module Rebuild
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
      EnvManager.new do |mgr|
        with_target_name( parameters.shift ) do |fullname|
          cmd = get_cmdline_tail( parameters )
          rbld_log.info("Going to modify \"#{fullname}\" with \"#{cmd}\"")
          mgr.modify!( fullname, cmd )
        end
      end
    end
  end
end
