#!/usr/bin/env ruby

require 'docker'

module Rebuild
  class Environment

    ENV_NAME_SEPARATOR = ':'
    private_constant :ENV_NAME_SEPARATOR
    INITIAL_TAG_NAME = 'initial'
    private_constant :INITIAL_TAG_NAME

    private

    def self.validate_param( name, value )
      raise "Invalid #{name} (#{value}), " \
            "it may contain a-z, A-Z, 0-9, - and " \
            "_ characters only" \
            unless value.match( /^[[:alnum:]\_\-]*$/ )
    end

    public

    def initialize(name, tag, api_obj)
      @name, @tag, @api_obj = name, tag, api_obj
    end

    def self.parse_name_tag(fullname)
      name, tag = fullname.match( /^([^:]*):?(.*)/ ).captures

      raise "Environment name not specified" if name.empty?
      validate_param( "environment name", name )
      validate_param( "environment tag", tag )

      [name, tag]
    end

    def self.validate_tag(tag_name, tag)
      validate_param( tag_name, tag )
    end

    def self.deduce_name_tag(fullname)
      name, tag = parse_name_tag( fullname )
      if tag.empty?
        tag = INITIAL_TAG_NAME
      end
      [name, tag]
    end

    def self.build_full_name(name, tag)
      "#{name}#{ENV_NAME_SEPARATOR}#{tag}"
    end

    attr_reader :name, :tag, :api_obj

    def to_s
      self.class.build_full_name(@name, @tag)
    end

    def ==(fullname)
        return false unless fullname.kind_of?(String)
        to_s == fullname
    end
  end

  class EnvManager

    private

    ENV_LABEL = 're-build-environment'
    ENV_NAME_PREFIX = 're-build-env-'
    ENV_RERUN_NAME_PREFIX = 're-build-env-rerun-'
    ENV_NAME_SEPARATOR = ':'
    MODIFIED_PREFIX='re-build-env-dirty-'
    MODIFIED_SEPARATOR='-rebuild-tag-'

    private_constant :ENV_LABEL
    private_constant :ENV_NAME_PREFIX
    private_constant :ENV_RERUN_NAME_PREFIX
    private_constant :ENV_NAME_SEPARATOR
    private_constant :MODIFIED_PREFIX
    private_constant :MODIFIED_SEPARATOR

    def add_environment( tag, api_obj )
      if match = tag.match(/^#{ENV_NAME_PREFIX}(.*)#{ENV_NAME_SEPARATOR}(.*)/)
        @all << Environment.new( *match.captures, api_obj )
      end
    end

    def add_modified_environment( name, api_obj )
      if match = name.match(/^\/#{MODIFIED_PREFIX}(.*)#{MODIFIED_SEPARATOR}(.*)/)
        @modified << Environment.new( *match.captures, api_obj )
      end
    end

    def self.internal_env_name( env_or_name, tag = nil )
      if env_or_name.respond_to?( :name ) \
        && env_or_name.respond_to?( :tag )
        "#{ENV_NAME_PREFIX}#{env_or_name.name}" \
        "#{ENV_NAME_SEPARATOR}#{env_or_name.tag}"
      else
        "#{ENV_NAME_PREFIX}#{env_or_name}#{ENV_NAME_SEPARATOR}#{tag}"
      end
    end

    def is_rebuild_object( object )
      labels = object.info['Labels']
      labels && labels[ENV_LABEL] == 'true'
    end

    def refresh_all_environments!
      @all = []
      Docker::Image.all.each do |img|
        rbld_log.debug("Found docker image #{img}")

        if is_rebuild_object( img )
          img.info['RepoTags'].each { |tag| add_environment( tag, img ) }
        end
      end
    end

    def refresh_modified_environments!
      @modified = []
      Docker::Container.all( :all => true ).each do |cont|
        rbld_log.debug("Found docker container #{cont}")

        if is_rebuild_object( cont )
          cont.info['Names'].each { |name| add_modified_environment( name, cont ) }
        end
      end
    end

    def refresh!
      refresh_all_environments!
      refresh_modified_environments!
    end

    def check_connectivity
      begin
        Docker.validate_version!
      rescue Docker::Error::VersionError => msg
        raise "Unsupported docker service: #{msg}"
      end
    end

    def initialize
      check_connectivity
      refresh!
      yield( self ) if block_given?
    end

    def delete_env(env)
      env.api_obj.remove( :name => self.class.internal_env_name(env) )
    end

    public

    attr_reader :all, :modified

    def remove!(fullname)
      raise "Environment is modified, commit or checkout first" \
        if @modified.include? fullname

      if idx = @all.index( fullname )
        delete_env( @all[idx] )
        @all.delete_at( idx )
      else
        raise "Unknown environment #{fullname}"
      end
    end
  end
end
