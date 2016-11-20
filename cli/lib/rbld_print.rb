require 'colorize'
require 'io/console'

module Rebuild
  module Printer
    class RbldPrinter
      private

      def self.progress_print(msg)
        STDOUT.print msg.light_green
        STDOUT.flush
      end

      public

      def self.error(msg)
        puts
        puts "    ERROR: #{msg}".light_red
        puts
      end

      def self.warning(msg)
         puts "WARNING: #{msg}".light_yellow
      end

      def self.progress(msg)
        puts
        puts "#{msg}".light_green
      end

      def self.trace(msg)
        puts "#{msg}".light_black
      end

      def self.raw_trace(msg)
        STDOUT.write( "#{msg}".light_black )
        STDOUT.flush
      end

      def self.inplace_trace(msg)
        raw_trace( msg[0...IO.console.winsize[1]] + "\r" ) \
          if STDOUT.tty?
      end

      def self.progress_start(msg)
        puts
        progress_print "#{msg} [.."
      end

      def self.progress_tick
        progress_print '.'
      end

      def self.progress_end
        progress_print '.]'
        puts
      end
    end

    def rbld_print
      RbldPrinter
    end
  end
end

include Rebuild::Printer
