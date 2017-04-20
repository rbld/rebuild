require_relative 'rbld_log'
require_relative 'rbld_utils'
require_relative 'rbld_verinfo'
require_relative 'rbld_engine'
require_relative 'rbld_plugins'

module Rebuild::CLI
  extend Rebuild::Utils::Errors

  rebuild_errors \
    EnvironmentNameEmpty: 'Environment name not specified',
    EnvironmentNameWithoutTagExpected: 'Environment tag must not be specified',
    EnvironmentNameError: 'Invalid %s, it may contain a-z, A-Z, 0-9, - and _ characters only',
    HandlerClassNameError: '%s'

  class Environment
    def initialize(env, opts = {})
      if env.respond_to?( :name ) && env.respond_to?( :tag )
        @name, @tag = env.name, env.tag
      else
        deduce_name_tag( env, opts )
        validate_name_tag(opts)
      end
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

  class Commands
    extend Enumerable

    private

    def self.deduce_cmd_name(handler_class)
      match = handler_class.name.match(/Rbld(.*)Command/)
      return nil unless match
      match.captures[0].gsub(/([^A-Z])([A-Z]+)/,'\1-\2').downcase
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
        raise HandlerClassNameError, klass.name
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
      handler = handler!( command )
      Rebuild::PlugMgr.instance.notify(:command, command, parameters) { return 100 }
      handler.run( parameters )
      handler.errno
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
      strings = names.map { |n| Environment.new(n).full }
      puts
      strings.sort.each { |s| puts "    #{prefix}#{s}"}
      puts
    end

    def engine_api
      @engine_api ||= Rebuild::Engine::API.new
      @engine_api
    end

    def warn_if_modified(env, action)
      rbld_print.warning "Environment is modified, #{action} original version" \
        if engine_api.environments.select( &:modified? ).include?( env )
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

    attr_reader :errno

    def usage
      puts <<END_USAGE

Usage: #{format_usage_text}
#{@description}

#{options_text}
END_USAGE
    end
  end

  module RunOptions
    def opts_text
      [["-p, --privileged", "Run environment with superuser privileges"]]
    end

    def parse_opts(parameters)
      replace_argv( parameters ) do
        opts = GetoptLong.new([ '--privileged', '-p', GetoptLong::NO_ARGUMENT ])
        runopts = {}
        opts.each do |opt, arg|
          case opt
          when '--privileged'
              runopts[:privileged] = true
          end
        end

        return runopts, ARGV
      end
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
