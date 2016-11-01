#!/usr/bin/env ruby

module Rebuild
  class RbldRmCommand < Command
    def initialize
      @usage = "rm [OPTIONS] [ENVIRONMENT[:TAG]]"
      @description = "Remove local environment"
    end

    legacy_run_implementation :rm
  end
end
