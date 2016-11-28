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
      Rebuild::EnvManager.new do |mgr|
        file = parameters[0]
        raise "File name must be specified" if !file
        raise "File #{file} does not exist" if !File::exist?(file)
        rbld_log.info("Going to load environment from #{file}")
        mgr.load!( file )
      end
    end
  end
end
