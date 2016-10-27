#!/usr/bin/env ruby

require_relative 'rbld_envmgr'

module Rebuild
  class RbldListCommand < Command
    def initialize
      @usage = "list [OPTIONS]"
      @description = "List local environments"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        names = mgr.all.map { |env| env.to_s }
        puts
        names.sort.each { |env| puts "    #{env}"}
        puts
      end
    end
  end
end
