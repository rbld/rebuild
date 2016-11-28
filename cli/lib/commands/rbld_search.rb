module Rebuild
  class RbldSearchCommand < Command
    def initialize
      @usage = "search [OPTIONS] [NAME[:TAG]|PREFIX]"
      @description = "Search remote registry for published environments"
    end

    def run(parameters)
      EnvManager.new do |mgr|
        with_target_name_tag( parameters[0] ) do |name, tag|
          tag = "" if name.empty?
          print_names( mgr.search( name, tag ) )
        end
      end
    end
  end
end
