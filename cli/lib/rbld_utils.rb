module Rebuild
  module Utils

    class Error < RuntimeError
      def initialize(pfx, fmt, msg)
        if not pfx.to_s.empty?
          super( msg.to_s.empty? ? pfx : "#{pfx}: #{msg}" )
        elsif not fmt.to_s.empty?
          super( sprintf( fmt, msg ) )
        else
          super( msg )
        end
      end

      def self.inherited( child_class )
        child_class.class_eval( "def initialize(msg); super( nil, nil, msg ); end" )
      end

      def self.msg_prefix(pfx)
        class_eval( "def initialize(msg = nil); super( \"#{pfx}\", nil, msg ); end" )
      end

      def self.msg_format(fmt)
        class_eval( "def initialize(msg); super( nil, \"#{fmt}\", msg ); end" )
      end
    end

  end
end
