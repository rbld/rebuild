#!/usr/bin/env ruby

require 'docker'
require 'etc'
require_relative 'rbld_print'

module Rebuild
  class Environment

    ENV_NAME_SEPARATOR = ':'
    private_constant :ENV_NAME_SEPARATOR
    INITIAL_TAG_NAME = 'initial'

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
    NAME_TAG_SEPARATOR='-rebuild-tag-'
    RBLD_OBJ_FILTER={:label => ["#{ENV_LABEL}=true"] }
    ENV_RUNNING_PREFIX='re-build-env-running-'

    private_constant :ENV_LABEL
    private_constant :ENV_NAME_PREFIX
    private_constant :ENV_RERUN_NAME_PREFIX
    private_constant :ENV_NAME_SEPARATOR
    private_constant :MODIFIED_PREFIX
    private_constant :NAME_TAG_SEPARATOR
    private_constant :RBLD_OBJ_FILTER
    private_constant :ENV_RUNNING_PREFIX

    def add_environment( tag, api_obj )
      if match = tag.match(/^#{ENV_NAME_PREFIX}(.*)#{ENV_NAME_SEPARATOR}(.*)/)
        @all << Environment.new( *match.captures, api_obj )
      end
    end

    def add_modified_environment( name, api_obj )
      if match = name.match(/^\/#{MODIFIED_PREFIX}(.*)#{NAME_TAG_SEPARATOR}(.*)/)
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

    def self.running_cont_name( env )
      "#{ENV_RUNNING_PREFIX}#{env.name}#{NAME_TAG_SEPARATOR}#{env.tag}"
    end

    def self.env_hostname( env, modified = false )
      "#{env.name}-#{env.tag}" + ( modified ? "-M" : "" )
    end

    def self.cont_run_settings
       %Q{ -v #{Dir.home}:#{Dir.home}                                 \
           -e REBUILD_USER_ID=#{Process.uid}                          \
           -e REBUILD_GROUP_ID=#{Process.gid}                         \
           -e REBUILD_USER_NAME=#{Etc.getlogin}                       \
           -e REBUILD_GROUP_NAME=#{Etc.getgrgid(Process.gid)[:name]}  \
           -e REBUILD_USER_HOME=#{Dir.home}                           \
           -e REBUILD_PWD=#{Dir.pwd}                                  \
           --security-opt label:disable                               \
       }
    end

    def self.run_external(cmdline)
      rbld_log.info("Executing external command #{cmdline}")
      system( cmdline )
      errcode = $?.exitstatus
      rbld_log.info( "External command returned with code #{errcode}" )
      raise CommandError, errcode if errcode != 0
    end

    def self.internal_rerun_env_name(name, tag)
      "#{ENV_RERUN_NAME_PREFIX}#{name}" \
      "#{NAME_TAG_SEPARATOR}#{tag}" \
      ":#{Environment::INITIAL_TAG_NAME}"
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

    def delete_cont_if_exists(name)
      rbld_containers.each do |cont|
        cont.info['Names'].each do |cname|
          rbld_log.debug("Checking if #{cname} matches /#{name}")
          cont.delete( :force => true ) if "/#{name}" == cname
        end
      end
    end

    def run_env_disposable(env, cmd)
      delete_cont_if_exists( self.class.running_cont_name( env ) )

      cmdline = %Q{
        docker run                                          \
             -i #{STDIN.tty? ? '-t' : ''}                   \
             --rm                                           \
             --name #{self.class.running_cont_name( env )}  \
             --hostname #{self.class.env_hostname( env )}   \
             #{self.class.cont_run_settings}                \
             #{env.api_obj.id}                              \
             "#{cmd.join(' ')}"                             \
      }

      self.class.run_external( cmdline )
    end

    def delete_all_dangling
      rbld_images( { :dangling => [ "true" ] } ).each do |env|
        rbld_log.info("Removing dangling image #{env}")
        env.remove
      end
    end

    def delete_rerun_image(name, tag)
      int_name = self.class.internal_rerun_env_name( name, tag )
      Docker::Image.all( :filter => int_name ).each do |img|
        rbld_log.info("Removing image #{int_name}")
        img.remove( :name => int_name )
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

    def run(fullname, cmd)
      rbld_print.warning "Environment is modified, running original version" \
        if @modified.include? fullname

      raise "Unknown environment #{fullname}" \
        unless idx = @all.index( fullname )

      run_env_disposable( @all[idx], cmd )
    end

    def checkout!(fullname, name, tag)
      raise "Unknown environment #{fullname}" unless @all.include? fullname

      if idx = @modified.index( fullname )
        rbld_log.info("Removing container #{@modified[idx].api_obj.info}")
        @modified[idx].api_obj.delete( :force => true )
      end

      delete_rerun_image( name, tag )
      @modified.delete_at( idx ) if idx
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
