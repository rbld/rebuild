#!/usr/bin/env ruby

module Rebuild
  class Commands
    extend Enumerable

    private

    COMMAND_PREFIX="re-build-cmd-"

    def self.script_path(name)
      File.join( File.dirname( __FILE__ ),
                 "..",
                 "libexec",
                 COMMAND_PREFIX + name )
    end

    def self.list_scripts
      commands_list = Dir[self.script_path( '*' )]
      commands_list.reject {|f| File.directory? f}
    end

    def self.list_commands
      self.list_scripts.map { |script| script.sub( /^.*#{COMMAND_PREFIX}/, '' )}
    end

    def self.deduce_cmd_name(handler_class)
      match = handler_class.name.match(/Rbld(.*)Command/)
      return nil unless match
      match.captures[0].downcase
    end

    def self.find_handler_class(command)
      @handler_classes.each do |klass|
        return klass if command == deduce_cmd_name( klass )
      end
      nil
    end

    KNOWN_COMMANDS=self.list_commands
    @handler_classes = []

    public

    def self.register_handler_class(klass)
      unless deduce_cmd_name( klass )
        raise LoadError.new("Failed to bind command handler class #{klass}")
      end

      @handler_classes << klass
    end

    def self.each
      KNOWN_COMMANDS.each { |cmd| yield( cmd ) }
      @handler_classes.each { |klass| yield( deduce_cmd_name( klass ) ) }
    end

    def self.run(command, parameters)
      parameters = parameters.join(" ")

      rbld_log.info( "Running #{command}(#{parameters})" )

      unless KNOWN_COMMANDS.include? command
        raise "Unknown command: #{command}"
      end

      system( "#{script_path( command )} #{parameters}" )

      errcode = $?.exitstatus

      rbld_log.info( "Command returned with code #{errcode}" )

      errcode
    end
  end

  class Command
    def self.inherited( handler_class )
      Commands.register_handler_class( handler_class )
      rbld_log.info( "Command handler class #{handler_class} registered" )
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
