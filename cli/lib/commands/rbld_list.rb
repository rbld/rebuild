module Rebuild::CLI
  class RbldListCommand < Command
    def initialize
      @usage = "list [OPTIONS]"
      @description = "List local environments"
    end

    run_prints :all
  end
end
