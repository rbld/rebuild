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
      wildcard = EnvManager.published_env_name( name, tag )
      rbld_log.info( "Searching for #{wildcard} (#{name}, #{tag})" )
      begin
        @api.search(wildcard).map do |n|
          rbld_log.debug( "Found #{n}" )
          name, tag = EnvManager.demungle_published_name( n )
          (name && tag) ? Environment.build_full_name(name, tag) : nil
        end.compact
      rescue DockerRegistry::Exception
        raise "Failed to search in #{@remote}"
      end
    end

    def publish(env)
      name = EnvManager.published_env_name( env.name, env.tag )
      tag = Environment::INITIAL_TAG_NAME
      name = "#{@remote}/#{name}"
      fullname = Environment::build_full_name( name, tag )

      img = env.api_obj
      img.tag( :repo => name, :tag => tag )

      begin
        img.push(nil, :repo_tag => fullname) do |log|
          progress = JSON.parse(log)["progress"]
          rbld_print.inplace_trace(progress) if progress
        end
      ensure
        img.remove( :name => fullname )
      end

    end
  end
end
