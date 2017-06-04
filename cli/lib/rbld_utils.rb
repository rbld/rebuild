require 'delegate'
require 'ruby-progressbar'
require 'json'

module Rebuild
  module Utils

    class Error < RuntimeError
      def initialize(fmt, msg)
        if not fmt.to_s.empty?
          if msg.kind_of?(Array)
            super( sprintf( fmt, *msg ) )
          elsif
            super( sprintf( fmt, msg ) )
          end
        else
          super( msg )
        end
      end

      def self.msg_format(fmt)
        class_eval( "def initialize(msg = nil); super( \"#{fmt}\", msg ); end" )
      end
    end

    class FullImageName
      def initialize(repo, tag)
        @repo = repo
        @tag = tag
        @full = "#{repo}:#{tag}"
      end

      def to_s
        @full
      end

      attr_reader :repo, :tag, :full
      alias_method :name, :repo
    end

    class EnvNameHolder
      def initialize(name, tag)
        @name, @tag = name, tag
        @full = "#{name}:#{tag}"
      end

      def to_s
        @full
      end

      attr_reader :name, :tag, :full
    end

    module Errors
      def rebuild_errors(definitions)
        definitions.each_pair do |name, msg_fmt|
          self.const_set(name.to_s,
            Class.new(Rebuild::Utils::Error) do
              msg_format msg_fmt
              private
              def self.defined_by_rebuild_error_helper
                true
              end
            end)
        end
      end

      alias rebuild_error rebuild_errors
    end

    class StopWatch
      def restart
        @start_time = Time.now
      end

      alias_method :initialize, :restart

      def time_ms
        (Time.now - @start_time).to_i * 1000
      end
    end

    class WithProgressBar < SimpleDelegator
      def initialize(target, methods = [], progressbar_class = ProgressBar, console_obj = STDOUT)
        if console_obj.tty?
          __init_progress__( progressbar_class, console_obj )
          methods = [ methods ] unless methods.respond_to? :each
          methods.each { |m| __create_hook__( m ) }
        end

        super(target)
      end

      private

      def __init_progress__(progressbar_class, console_obj)
        @__progressbar__ = progressbar_class.create(title: 'Working',
                                                    length: 60,
                                                    total: nil,
                                                    output: console_obj)
        @__stopwatch__ = StopWatch.new
        @__first_call__ = true
      end

      def __create_hook__(name)
        instance_eval(
          %Q{
              def #{name}(*args)
                __do_tick__
                super
              end
            }
        )
      end

      def __do_tick__(*args)
        if @__first_call__ || @__stopwatch__.time_ms >= 200
          @__progressbar__.increment
          @__stopwatch__.restart
          @__first_call__ = false
        end
      end
    end

    class SafeJSONParser
      def initialize(string)
        @json = JSON.parse( string )
        rescue
      end

      def [](key)
        get( key )
      end

      def get(key)
        key = ( @json && @json.has_key?( key ) ) ? @json[key] : nil
        yield key if key && block_given?
        key
      end
    end
  end
end
