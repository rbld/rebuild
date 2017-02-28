require 'docker_registry2'
require_relative 'rbld_log'
require_relative 'rbld_utils'

module Rebuild
  module Registry
  module Docker
    module EnvironmentImage
      def self.publish(img, target_url)
        api_obj = img.api_obj

        api_obj.tag( repo: target_url.repo, tag: target_url.tag )

        begin
          rbld_log.info( "Pushing #{target_url.full}" )
          api_obj.push(nil, :repo_tag => target_url.full) do |log|
            trace_progress( log )
          end
        ensure
          api_obj.remove( :name => target_url.full )
        end
      end

      def self.deploy(source_url, api_class = ::Docker::Image)
        begin
          rbld_log.info( "Pulling #{source_url.full}" )
          img = api_class.create(:fromImage => source_url.full) do |log|
            trace_progress( log )
          end
          yield img
        ensure
          img.remove( :name => source_url.full ) if img
        end
      end

      private

      def self.trace_progress(log_item)
        begin
          line = JSON.parse( log_item )["progress"]
          rbld_print.inplace_trace( line ) if line
        rescue
        end
      end

    end
  end
  end
end
