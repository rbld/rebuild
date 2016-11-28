module Rebuild::CLI
  class RbldSaveCommand < Command
    private

    def default_file(env)
      "#{env.name}-#{env.tag}.rbld"
    end

    public

    def initialize
      @usage = "save [OPTIONS] [ENVIRONMENT] [FILE]"
      @description = "Save local environment to file"
    end

    def run(parameters)
      Rebuild::EnvManager.new do |mgr|
        env, file = parameters
        env = Environment.new( env )
        file = default_file( env ) if !file or file.empty?
        rbld_log.info("Going to save #{env} to #{file}")
        mgr.save(env.full, file)
      end
    end
  end
end
