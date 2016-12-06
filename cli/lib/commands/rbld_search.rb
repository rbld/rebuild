module Rebuild::CLI
  class RbldSearchCommand < Command
    def initialize
      @usage = "search [OPTIONS] [NAME[:TAG]|PREFIX]"
      @description = "Search remote registry for published environments"
    end

    def run(parameters)
      env = Environment.new(parameters[0], allow_empty: true)
      print_names( engine_api.search( env ) )
    end
  end
end
