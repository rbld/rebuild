#!/usr/bin/env ruby

module Rebuild
  class RbldStatusCommand < Command
    def initialize
      @usage = "status [OPTIONS]"
      @description = "List modified environments"
    end

    run_prints :modified, "modified: "
  end
end
