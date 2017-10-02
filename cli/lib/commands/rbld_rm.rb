module Rebuild::CLI
  class RbldRmCommand < Command
    def initialize
      @usage = "[OPTIONS] [ENVIRONMENT[:TAG]]... -- COMMANDS"
      @description = "Remove one or more local environments"
      @options = [
                  ["-f, --force", "force remove modified environments"]
                 ]
    end

    def parse_opts(parameters)
      replace_argv( parameters ) do
        opts = GetoptLong.new([ '--force', '-f', GetoptLong::NO_ARGUMENT ])
        runopts = {}
        opts.each do |opt, arg|
          case opt
          when '--force'
            runopts[:force] = true
          end
        end
        return runopts, ARGV
      end
    end

    def run(parameters)
      runopts, parameters = parse_opts( parameters )
      raise EnvironmentNameEmpty unless parameters.any?
      parameters.each do |parameter|
        env = Environment.new( parameter )
        rbld_log.info("Going to checkout #{env} before removal")
        engine_api.checkout!( env ) if runopts[:force]
        rbld_log.info("Going to remove #{env}")
        engine_api.remove!( env )
      end
    end
  end
end
