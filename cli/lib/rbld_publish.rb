#!/usr/bin/env ruby

module Rebuild
  class RbldPublishCommand < Command
    def initialize
      @usage = "publish [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Publish environment on remote registry"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        with_target_name( parameters[0] ) do |fullname, name, tag|
          rbld_log.info("Going to publish \"#{fullname}\"")
          mgr.publish( fullname, name, tag )
        end
      end
    end
  end
end
