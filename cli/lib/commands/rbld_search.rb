module Rebuild::CLI
  class RbldSearchCommand < Command
    def initialize
      @usage = "search [OPTIONS] [NAME[:TAG]|PREFIX]"
      @description = "Search remote registry for published environments"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env = Environment.new(parameters[0], allow_empty: true)
        print_names( mgr.search( env.name, env.tag ) )
      end
    end
  end
end
