module Rebuild
  class CommandError < RuntimeError
    def initialize(errcode)
      @code = errcode
    end

    attr_reader :code
  end

  class Commands
    extend Enumerable

    private

    def self.deduce_cmd_name(handler_class)
      match = handler_class.name.match(/Rbld(.*)Command/)
      return nil unless match
      match.captures[0].downcase
    end

    def self.handler!(command)
      @handler_classes.each do |klass|
        return klass.new if command == deduce_cmd_name( klass )
      end

      raise "Unknown command: #{command}"
    end

    @handler_classes = []

    public

    def self.register_handler_class(klass)
      unless deduce_cmd_name( klass )
        raise LoadError.new("Failed to bind command handler class #{klass}")
      end

      @handler_classes << klass
    end

    def self.each
      @handler_classes.each { |klass| yield( deduce_cmd_name( klass ) ) }
    end

    def self.usage(command)
      handler!( command ).usage
    end

    def self.run(command, parameters)
      handler!( command ).run( parameters )
    end
  end

  class Command

    private

    def self.inherited( handler_class )
      Commands.register_handler_class( handler_class )
      rbld_log.info( "Command handler class #{handler_class} registered" )
    end

    def options_text
      options = (@options || []) + [["-h, --help", "Print usage"]]
      text = ""
      options.each { |o| text << "  #{o[0].ljust(30)}#{o[1]}\n" }
      text
    end

    def replace_argv(parameters)
      orig_argv = ARGV.clone
      ARGV.clear
      parameters.each { |x| ARGV << x }
      yield
      ARGV.clear
      orig_argv.each { |x| ARGV << x }
    end

    def print_names(names, prefix = '')
      strings = names.map { |n| n.to_s }
      puts
      strings.sort.each { |s| puts "    #{prefix}#{s}"}
      puts
    end

    def print_env_list(retriever, prefix = '')
      print_names( EnvManager.new.send( retriever ), prefix )
    end

    def self.run_prints( retriever, prefix = '' )
      code = %Q{
        def run(parameters)
          print_env_list( \"#{retriever}\".to_sym, \"#{prefix}\" )
        end
      }
      class_eval( code )
    end

    def with_target_name(parameter)
      raise "Environment name not specified" if !parameter
      name, tag = Environment.deduce_name_tag( parameter )
      yield Environment.build_full_name( name, tag ), name, tag
    end

    def with_target_name_initial_tag(parameter)
      raise "Environment name not specified" if !parameter
      name, tag = Environment.parse_name_tag( parameter )
      raise "Environment name not specified" if name.empty?
      raise "Environment tag must not be specified" unless tag.empty?
      tag = Environment::INITIAL_TAG_NAME
      yield Environment.build_full_name( name, tag ), name, tag
    end

    def with_target_name_tag(parameter)
      yield parameter ? Environment.parse_name_tag( parameter )
                      : ["", ""]
    end

    def get_cmdline_tail(parameters)
      parameters.shift if parameters[0] == '--'
      parameters
    end

    public

    def format_usage_text
      text = ""
      if @usage.respond_to?(:each)
        text << "\n"
        @usage.each do |mode|
          text << "\n  rbld #{mode[:syntax]}\n\n" \
                  "    #{mode[:description]}\n"
        end
      else
        text << "rbld #{@usage}\n"
      end
      text
    end

    def usage
      puts <<END_USAGE

Usage: #{format_usage_text}
#{@description}

#{options_text}
END_USAGE
    end
  end

  class Main

    def self.usage
      usage_text = <<USAGE
Usage:
  rbld help                Show this help screen
  rbld help COMMAND        Show help for COMMAND
  rbld COMMAND [PARAMS]    Run COMMAND with PARAMS

rebuild: Zero-dependency, reproducible build environments

Commands:

USAGE

      Commands.sort.each { |cmd| usage_text << "  #{cmd}\n"}

      usage_text
    end
  end
end
