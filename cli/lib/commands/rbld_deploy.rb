module Rebuild
  class RbldDeployCommand < Command
    def initialize
      @usage = "deploy [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Deploy environment from remote registry"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        with_target_name( parameters[0] ) do |fullname, name, tag|
          cmd = get_cmdline_tail( parameters )
          rbld_log.info("Going to deploy \"#{fullname}\"")
          mgr.deploy!( fullname, name, tag )
        end
      end
    end
  end
end
