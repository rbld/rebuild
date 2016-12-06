module Rebuild::CLI
  class RbldLoadCommand < Command
    private

    def default_file(name, tag)
      "#{name}-#{tag}.rbld"
    end

    public

    def initialize
      @usage = "load [OPTIONS] [FILE]"
      @description = "Load environment from file"
    end

    def run(parameters)
      file = parameters[0]
      raise "File name must be specified" if !file
      raise "File #{file} does not exist" if !File::exist?(file)
      rbld_log.info("Going to load environment from #{file}")
      engine_api.load!( file )
      rbld_print.progress "Successfully loaded environment from #{file}\n"
    end
  end
end
