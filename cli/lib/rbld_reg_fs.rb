require_relative 'rbld_log'
require_relative 'rbld_utils'
require_relative 'rbld_fileops'

module Rebuild
  module Registry
  module FS
    extend Rebuild::Utils::Errors

    rebuild_error FSLookupError: 'Failed to access registry at %s'

    class API
      FILE_SFX = '.rbe'
      private_constant :FILE_SFX

      def initialize(path)
        @path = path
        rbld_log.info( "Connecting to registry #{@path}" )
        raise FSLookupError, @path unless Dir.exists?( @path )
      end

      def search(name = nil, tag = nil)
        wildcard = File.join( tag.to_s.empty? ? ["#{name}*", '*' ] : [name, tag] ) + FILE_SFX

        rbld_log.info( "Searching for #{wildcard}" )

        Dir.glob( File.join( @path, wildcard ) ).map do |n|

          rbld_log.debug( "Found entry: #{n}" )

          pfx = File.join( @path,'' )
          sfx = FILE_SFX
          s = File::SEPARATOR
          nametag = n.match( /^#{pfx}([^#{s}]+)#{s}([^#{s}]+)#{sfx}$/ ).captures
          Rebuild::Utils::FullImageName.new( *nametag )
        end
      end

      def publish(name, tag, img)
        reg_dir = File.join( @path, name )
        reg_file = File.join( reg_dir, tag ) + FILE_SFX

        rbld_log.info( "Pushing to #{@path}" )

        FileUtils.mkdir_p( File.join( reg_dir ) )

        begin
          ef = Rebuild::Engine::EnvironmentFile.new(reg_file)
          ef.save!( Rebuild::Utils::FullImageName.new( name, tag ), img.identity )
        rescue
          FileUtils.rm_rf( reg_file )
          raise
        end
      end

      def deploy(name, tag, api_class = ::Docker::Image)
        reg_file = File.join( @path, name, tag ) + FILE_SFX
        rbld_log.info( "Pulling from #{@path}" )
        Rebuild::Engine::EnvironmentFile.new(reg_file).load!
      end

    end
  end
  end
end
