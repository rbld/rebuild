module Rebuild::CLI
  class RbldVersionCommand < Command
    def initialize
      @usage = "[OPTIONS]"
      @description = "Show the Rebuild version information"
    end

    def run(parameters)
      puts "Rebuild CLI version #{Rebuild::Version.info}"
    end
  end
end
