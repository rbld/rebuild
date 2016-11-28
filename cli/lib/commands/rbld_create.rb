require 'getoptlong'

module Rebuild::CLI
  class RbldCreateCommand < Command
    def initialize
      @usage = "create [OPTIONS] [ENVIRONMENT]"
      @description = "Create a new environment"
      @options = [
                  ["-b NAME, --base NAME", "Base image from Docker Hub"],
                  ["-f NAME, --basefile NAME", "Base file"]
                 ]
    end

    def parse_opts(parameters)
      replace_argv( parameters ) do
        opts = GetoptLong.new([ '--base', '-b', GetoptLong::REQUIRED_ARGUMENT ],
                              [ '--basefile', '-f', GetoptLong::REQUIRED_ARGUMENT ])
        base = basefile = nil
        opts.each do |opt, arg|
          case opt
            when '--base'
              base = arg
            when '--basefile'
              basefile = arg
          end
        end

        raise "Exactly one environment base must be specified" \
          if base && basefile

        raise "Environment base not specified" \
          unless base || basefile

        raise "Base file #{basefile} does not exist" \
          if basefile && !File.file?(basefile)

        return base, basefile, ARGV
      end
    end

    def run(parameters)
      base, basefile, parameters = parse_opts( parameters )

      Rebuild::EnvManager.new do |mgr|
        env = Environment.new( parameters[0], force_no_tag: true )
        rbld_log.info("Going to create #{env} from #{base || basefile}")
        mgr.create!(base, basefile, env.full, env.name, env.tag)
      end
    end
  end
end
