require_relative 'rbld_utils'

module Rebuild::CLI
  class CommandError < Rebuild::Utils::Error
    def initialize(errcode)
      @code = errcode
    end

    attr_reader :code
  end

  class EnvironmentNameEmpty < Rebuild::Utils::Error
    msg_prefix 'Environment name not specified'
  end

  class EnvironmentNameWithoutTagExpected < Rebuild::Utils::Error
    msg_prefix 'Environment tag must not be specified'
  end

  class EnvironmentNameError < Rebuild::Utils::Error
    msg_format 'Invalid %s, it may contain a-z, A-Z, 0-9, - and _ characters only'
  end

  class Environment
    def initialize(cli_param, opts = {})
      deduce_name_tag( cli_param, opts )
      validate_name_tag(opts)
      @full = "#{@name}:#{@tag}"
    end

    def self.validate_component( name, value )
      raise EnvironmentNameError, "#{name} (#{value})" \
        unless value.match( /^[[:alnum:]\_\-]*$/ )
    end

    def to_s
      @full
    end

    attr_reader :name, :tag, :full

    private

    def parse_name_tag(cli_param, opts)
      if opts[:allow_empty] && (!cli_param || cli_param.empty?)
        @name, @tag = '', ''
      elsif !cli_param || cli_param.empty?
        raise EnvironmentNameEmpty
      else
        @name, @tag = cli_param.match( /^([^:]*):?(.*)/ ).captures
        @tag = '' if @name.empty?
      end
    end

    def deduce_name_tag(cli_param, opts)
      parse_name_tag( cli_param, opts )

      raise EnvironmentNameWithoutTagExpected \
        if opts[:force_no_tag] && !@tag.empty?

      @tag = 'initial' if @tag.empty? && !opts[:allow_empty]
    end

    def validate_name_tag(opts)
      raise EnvironmentNameEmpty if @name.empty? && !opts[:allow_empty]
      self.class.validate_component( "environment name", @name ) unless @name.empty?
      self.class.validate_component( "environment tag", @tag ) unless @tag.empty?
    end
  end

  class HandlerClassNameError < Rebuild::Utils::Error
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
        raise HandlerClassNameError, "#{klass.name}"
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
      print_names( Rebuild::EnvManager.new.send( retriever ), prefix )
    end

    def self.run_prints( retriever, prefix = '' )
      class_eval %Q{
        def run(parameters)
          print_env_list( \"#{retriever}\".to_sym, \"#{prefix}\" )
        end
      }
    end

    def get_cmdline_tail(parameters)
      parameters.shift if parameters[0] == '--'
      parameters
    end

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

    public

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
