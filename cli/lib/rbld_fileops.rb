require 'docker'
require_relative 'rbld_utils'
require_relative 'rbld_print'

module Rebuild::Engine
  extend Rebuild::Utils::Errors

  rebuild_errors \
   EnvironmentLoadFailure: 'Failed to load environment from %s',
   EnvironmentSaveFailure: 'Failed to save environment %s to %s'

  class EnvironmentFile
    def initialize(filename, docker_api = Docker)
      @filename, @docker_api = filename, docker_api
    end

    def load!
      loaded_name = nil

      with_gzip_reader do |gz|
        Docker::Image.load(gz) do |response|
          Rebuild::Utils::SafeJSONParser.new( response ).get( 'stream' ) do |s|
            response = s
          end

          if m = response.match( /Loaded image: (.*)$/ )
            loaded_name = m.captures[0]
          elsif m = response.match( /The image (.*) already exists/ )
            loaded_name = m.captures[0]
          end
        end
      end

      if loaded_name
        env = Environment.from_image( loaded_name, nil )
        return Rebuild::Utils::EnvNameHolder.new( env.name, env.tag )
      else
        return nil
      end

      rescue => msg
        rbld_print.trace( msg )
        raise EnvironmentLoadFailure, @filename
    end

    def save!(name, identity)
      with_gzip_writer do |gz|
        Docker::Image.save_stream( identity ) { |chunk| gz.write chunk }
      end

      rescue => msg
        rbld_print.trace( msg )
        raise EnvironmentSaveFailure, [name, @filename]
    end

    private

    def with_gzip_writer
      begin
        File.open(@filename, 'w') do |f|
          f.binmode
          gz = Zlib::GzipWriter.new(f)
          begin
            yield Rebuild::Utils::WithProgressBar.new( gz, :write )
          ensure
            gz.close
          end
        end
      rescue
        FileUtils::safe_unlink( @filename )
        raise
      end
    end

    def with_gzip_reader
      Zlib::GzipReader.open( @filename ) do |gz|
        begin
          yield Rebuild::Utils::WithProgressBar.new( gz, :read )
        ensure
          gz.close
        end
      end
    end
  end

end
