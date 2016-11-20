#!/usr/bin/env ruby

module Rebuild
  class RbldCheckoutCommand < Command
    def initialize
      @usage = "checkout [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Discard environment modifications"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        with_target_name( parameters[0] ) do |fullname, name, tag|
          rbld_log.info("Going to checkout #{fullname}")
          mgr.checkout!(fullname, name, tag)
        end
      end
    end
  end
end
