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
  end
end
