module Rebuild::CLI
  class RbldListCommand < Command
    def initialize
      @usage = "[OPTIONS]"
      @description = "List local environments"
    end

    def run(parameters)
      print_names( engine_api.environments )
    end
  end
end
