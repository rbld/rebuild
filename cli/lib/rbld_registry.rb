#!/usr/bin/env ruby

require 'docker_registry2'
require_relative 'rbld_print'

module Rebuild
  class Registry
    def initialize(remote)
      @remote = remote
      begin
        rbld_log.info( "Connecting to registry #{@remote}" )
        @api = DockerRegistry.connect("http://#{@remote}")
      rescue StandardError
        raise "Failed to access the registry at #{@remote}"
      end
    end

    def search(name, tag)
      rbld_print.progress "Searching in #{@remote}..."
      wildcard = EnvManager.published_env_name( name, tag )
      rbld_log.info( "Searching for #{wildcard} (#{name}, #{tag})" )
      begin
        @api.search(wildcard).map do |n|
          rbld_log.debug( "Found #{n}" )
          name, tag = EnvManager.demungle_published_name!( n )
          Environment.build_full_name(name, tag)
        end
      rescue DockerRegistry::Exception
        raise "Failed to search in #{@remote}"
      end
    end
  end
end
