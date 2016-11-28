module Rebuild
  class RbldSaveCommand < Command
    private

    def default_file(name, tag)
      "#{name}-#{tag}.rbld"
    end

    public

    def initialize
      @usage = "save [OPTIONS] [ENVIRONMENT] [FILE]"
      @description = "Save local environment to file"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        env, file = parameters
        with_target_name( env ) do |fullname, name, tag|
          file = default_file( name, tag ) if !file or file.empty?
          rbld_log.info("Going to save #{fullname} to #{file}")
          mgr.save(fullname, file)
        end
      end
    end
  end
end
