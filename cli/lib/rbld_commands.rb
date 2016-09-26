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

    KNOWN_COMMANDS=self.list_commands

    public

    def self.each
      KNOWN_COMMANDS.each { |cmd| yield( cmd ) }
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
