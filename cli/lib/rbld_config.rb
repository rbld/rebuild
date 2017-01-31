require 'parseconfig'

module Rebuild
  class Remote
    def initialize(cfg)
      return unless cfg

      if @name = cfg['REMOTE_NAME']
        @type = cfg["REMOTE_TYPE_#{@name}"]
        @path = cfg["REMOTE_#{@name}"]
      end
    end

    def validate!
      unless @valid
        raise 'Remote not defined' unless @name
        raise 'Remote type not defined' unless @type
        raise 'Remote location not defined' unless @path

        @valid = true
      end

      self
    end

    attr_reader :name, :type, :path
  end

  class Config
    def initialize()
      cfg_file = File.join( Dir.home, '.rbld', 'rebuild.conf' )
      cfg = File.exist?( cfg_file ) ? ParseConfig.new( cfg_file ) : nil
      @remote = Remote.new( cfg )
    end

    def remote!
      @remote.validate!
    end
  end
end
