require 'parseconfig'

module Rebuild
  class Config
    def initialize()
      cfg_file = File.join( Dir.home, '.rbld', 'rebuild.conf' )

      if File.exist?( cfg_file )
        cfg = ParseConfig.new( cfg_file )
        rname = cfg['REMOTE_NAME']
        @remote = rname ? cfg["REMOTE_#{rname}"] : nil
      end
    end

    def remote!
      raise 'Remote not defined' unless @remote
      @remote
    end
  end
end
