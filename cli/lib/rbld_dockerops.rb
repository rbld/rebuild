require 'docker_registry2'
require_relative 'rbld_log'
require_relative 'rbld_utils'
require 'fancy_gets'

module Rebuild
  module Registry
  module Docker
    extend Rebuild::Utils::Errors

    rebuild_errors \
      RegistryOperationError: nil,
      RegistryNotAuthenticatedError: nil

    class EnvironmentImage
      include FancyGets

      def initialize(api_module = ::Docker)
        @api_module = api_module
      end

      def publish(img, target_url)
        try_with_login { try_publish( img, target_url ) }
      end

      def deploy(source_url)
        try_with_login do
          try_deploy( source_url ) { |img| yield img }
        end
      end

      private

      def try_with_login
        begin
          yield
        rescue RegistryNotAuthenticatedError
          do_login
          yield
        end
      end

      def do_login
        puts
        puts "Login required"
        puts
        print "Username: "
        user = STDIN.gets.chomp
        print "Email: "
        email = STDIN.gets.chomp
        print "Password: "
        pwd = gets_password
        @api_module.creds = { 'username' => user,
                              'password' => pwd,
                              'email' => email }
      end

      def try_publish(img, target_url)
        api_obj = img.api_obj
        api_obj.tag( repo: target_url.repo, tag: target_url.tag )

        begin
          rbld_log.info( "Pushing #{target_url.full}" )
          @last_error = nil
          api_obj.push(nil, :repo_tag => target_url.full) do |log|
            process_log( log )
          end
          raise_last_error
        ensure
          api_obj.remove( :name => target_url.full )
        end
      end

      def try_deploy(source_url)
        begin
          rbld_log.info( "Pulling #{source_url.full}" )
          @last_error = nil
          img = @api_module::Image.create(:fromImage => source_url.full) do |log|
            process_log( log )
          end
          raise_last_error
          yield img
        ensure
          img.remove( :name => source_url.full ) if img
        end
      end

      def process_log(log_item)
        begin
          json = JSON.parse( log_item )
        rescue
        else
          trace_progress( json['progress'] )
          save_last_error( json['errorDetail'] )
        end
      end

      def trace_progress(line)
        rbld_print.inplace_trace( line ) if line
      end

      def save_last_error(line)
        @last_error = line['message'] if line
      end

      def raise_last_error
        case @last_error
          when nil
            # No error
          when /authentication required/, /unauthorized/
            raise RegistryNotAuthenticatedError, @last_error
          else
            raise RegistryOperationError, @last_error
        end

      end

    end
  end
  end
end
