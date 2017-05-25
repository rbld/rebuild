require 'docker_registry'
require 'os'
require_relative 'rbld_log'
require_relative 'rbld_utils'
require_relative 'rbld_dockerops'

module Rebuild
  module Registry
  module DockerHub
    extend Rebuild::Utils::Errors

    rebuild_errors \
      IndexConnectionError: 'Failed to access registry at %s',
      InternalNameParsingError: 'Failed to parse internal name'

    class Entry
      REGISTRY_ENDPOINT = 'docker.io'
      NAME_PFX = 'rbe-'
      TAG_PFX = '-rt-'
      private_constant :NAME_PFX, :TAG_PFX, :REGISTRY_ENDPOINT

      def initialize(name, tag, path = nil)
        @name, @tag = name, tag
        @url = Rebuild::Utils::FullImageName.new( "#{REGISTRY_ENDPOINT}/#{path}",
                                                  "#{NAME_PFX}#{@name}#{TAG_PFX}#{@tag}" ) if path
      end

      def self.by_internal_name( int_name )
        m = int_name.match(/^#{NAME_PFX}(.*)#{TAG_PFX}(.*)/)
        raise InternalNameParsingError, int_name unless m
        new( *m.captures )
      end

      def match( name, tag )
        name, tag = name.to_s, tag.to_s
        return tag.empty? ? @name.start_with?( name )
                          : (@name == name && @tag.start_with?( tag ))
      end

      attr_reader :name, :tag, :url
    end

    class API
      INDEX_ENDPOINT = 'index.docker.io'
      private_constant :INDEX_ENDPOINT

      def initialize(path)
        @path = path
        override_cert_file
        rbld_log.info( "Connecting to DockerHub #{@path}" )
        begin
          endpoint = ENV['RBLD_OVERRIDE_INDEX_ENDPOINT'] || INDEX_ENDPOINT
          @index = DockerRegistry::Registry.new("https://#{endpoint}")
          @index.ping
        rescue StandardError
          raise IndexConnectionError, endpoint
        end
      end

      def search_repos
        @index.search( @path ).map( &:name ).find_all { |n| n.start_with?("#{@path}/") }
      end

      def search(name = nil, tag = nil)
        rbld_log.info( "Searching for #{name}:#{tag}" )

        repo = @index.search(@path).detect { |e| e.name == @path }

        return [] unless repo

        repo.tags.map do |e|
          parse_entry( e.name['name'] )
        end.compact.find_all do |e|
          e.match( name, tag )
        end
      end

      def publish(name, tag, img)
        url = Entry.new( name, tag, @path ).url
        Docker::EnvironmentImage.new.publish( img, url )
      end

      def deploy(name, tag, api_module = ::Docker)
        url = Entry.new( name, tag, @path ).url
        Docker::EnvironmentImage.new(api_module).deploy( url ) { |img| yield img }
      end

      private

      def parse_entry(internal_name)
        rbld_log.debug( "Parsing internal name '#{internal_name}'" )
        begin
          Entry.by_internal_name( internal_name )
        rescue InternalNameParsingError => msg
          rbld_log.warn( msg )
          return nil
        end
      end

      def override_cert_file
        ENV['SSL_CERT_FILE'] = ssl_cert_file if OS.windows?
      end

      def ssl_cert_file
        File.join( __dir__, 'data', 'dockerhub-cacert.pem' )
      end
    end
  end
  end
end
