require 'docker_registry2'
require_relative 'rbld_log'
require_relative 'rbld_utils'

module Rebuild
  module Registry
  module Docker
    extend Rebuild::Utils::Errors

    rebuild_error RegistryOperationError: nil

    module EnvironmentImage
      def self.publish(img, target_url)
        api_obj = img.api_obj

        api_obj.tag( repo: target_url.repo, tag: target_url.tag )

        begin
          rbld_log.info( "Pushing #{target_url.full}" )
          api_obj.push(nil, :repo_tag => target_url.full) do |log|
            process_log( log )
          end
        ensure
          api_obj.remove( :name => target_url.full )
        end
      end

      def self.deploy(source_url, api_class = ::Docker::Image)
        begin
          rbld_log.info( "Pulling #{source_url.full}" )
          img = api_class.create(:fromImage => source_url.full) do |log|
            process_log( log )
          end
          yield img
        ensure
          img.remove( :name => source_url.full ) if img
        end
      end

      private

      def self.process_log(log_item)
        begin
          json = JSON.parse( log_item )
        rescue
        else
          trace_progress( json['progress'] )
          raise_error( json['errorDetail'] )
        end
      end

      def self.trace_progress(line)
        rbld_print.inplace_trace( line ) if line
      end

      def self.raise_error(line)
        raise RegistryOperationError, line['message'] if line
      end

    end
  end
  end
end
