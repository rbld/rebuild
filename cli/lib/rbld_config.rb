require 'parseconfig'

module Rebuild
  class Config
    def initialize()
      cfg = ParseConfig.new( File.join( File.dirname( __FILE__ ),
                             "..", "etc", "rebuild.conf" ) )

      rname = cfg['REMOTE_NAME']
      @remote = rname ? cfg["REMOTE_#{rname}"] : nil
    end

    def remote!
      raise 'Remote not defined' unless @remote
      @remote
    end
  end
end
