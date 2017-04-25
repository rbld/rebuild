module Rebuild::CLI
  class RbldStatusCommand < Command
    def initialize
      @usage = "[OPTIONS]"
      @description = "List modified environments"
    end

    def run(parameters)
      print_names( engine_api.environments.select( &:modified? ), 'modified: ' )
    end
  end
end
