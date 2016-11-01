#!/usr/bin/env ruby

module Rebuild
  class RbldRmCommand < Command
    def initialize
      @usage = "rm [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Remove local environment"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        with_target_name( parameters[0] ) do |fullname|
          rbld_log.info("Going to remove #{fullname}")
          mgr.remove!( fullname )
        end
      end
    end
  end
end
