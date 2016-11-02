#!/usr/bin/env ruby

require 'docker'
require_relative 'rbld_print'

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
    RBLD_OBJ_FILTER={:label => ["re-build-environment=true"] }

    private_constant :ENV_LABEL
    private_constant :ENV_NAME_PREFIX
    private_constant :ENV_RERUN_NAME_PREFIX
    private_constant :ENV_NAME_SEPARATOR
    private_constant :MODIFIED_PREFIX
    private_constant :MODIFIED_SEPARATOR
    private_constant :RBLD_OBJ_FILTER

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

    def rbld_images(filters = nil)
      filters = RBLD_OBJ_FILTER.merge( filters || {} )
      Docker::Image.all( :filters => filters.to_json )
    end

    def rbld_containers(filters = nil)
      filters = RBLD_OBJ_FILTER.merge( filters || {} )
      Docker::Container.all( :all => true, :filters => filters.to_json )
    end

    def refresh_all_environments!
      @all = []
      rbld_images.each do |img|
        rbld_log.debug("Found docker image #{img}")
        img.info['RepoTags'].each { |tag| add_environment( tag, img ) }
      end
    end

    def refresh_modified_environments!
      @modified = []
      rbld_containers.each do |cont|
        rbld_log.debug("Found docker container #{cont}")
        cont.info['Names'].each { |name| add_modified_environment( name, cont ) }
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

    def delete_all_dangling
      rbld_images( { :dangling => [ "true" ] } ).each do |env|
        rbld_log.info("Removing dangling image #{env}")
        env.remove
      end
    end

    def with_gzip_writer( filename )
      begin
        File.open(filename, 'w') do |f|
          gz = Zlib::GzipWriter.new(f)
          yield gz
          gz.close
        end
      rescue
        FileUtils::safe_unlink(filename)
        raise
      end
    end

    def with_gzip_reader( filename )
      Zlib::GzipReader.open( filename ) do |gz|
        yield gz
        gz.close
      end
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

    def save(fullname, filename)
      rbld_print.warning "Environment is modified, saving original version" \
        if @modified.include? fullname

      if idx = @all.index(fullname)
        begin
          with_gzip_writer( filename ) do |gz|
            int_name = self.class.internal_env_name(@all[idx])
            Docker::Image.save_stream( int_name ) do |chunk|
              gz.write chunk
            end
          end
        rescue => e
          raise "Failed to save environment "\
                "#{fullname} to #{filename} (#{e})"
        else
          rbld_print.progress "Successfully saved environment "\
                              "#{fullname} to #{filename}"
        end
      else
        raise "Unknown environment #{fullname}"
      end
    end

    def load!(filename)
      begin
        with_gzip_reader( filename ) { |gz| Docker::Image.load(gz) }
      rescue => e
        raise "Failed to load environment from #{filename} (#{e})"
      else
        rbld_print.progress "Successfully loaded environment from #{filename}"
        # If image with the same name but another
        # ID existed before load it becomes dangling
        # and should be ditched
        delete_all_dangling
        refresh!
      end
    end

  end
end
