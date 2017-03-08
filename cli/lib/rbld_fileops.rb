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
      with_gzip_reader { |gz| Docker::Image.load(gz) }

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
            yield gz
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
          yield gz
        ensure
          gz.close
        end
      end
    end
  end

end
