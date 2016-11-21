#!/usr/bin/env ruby

require 'docker'
require 'etc'
require 'thread'

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
    ENV_ENTRYPOINT='/rebuild/re-build-entry-point'
    BOOTSTRAP_FILE_NAMES = ["re-build-bootstrap-utils",
                            "re-build-entry-point",
                            "re-build-env-prepare",
                            "rebuild.rc"]

    private_constant :ENV_LABEL
    private_constant :ENV_NAME_PREFIX
    private_constant :ENV_RERUN_NAME_PREFIX
    private_constant :ENV_NAME_SEPARATOR
    private_constant :MODIFIED_PREFIX
    private_constant :NAME_TAG_SEPARATOR
    private_constant :RBLD_OBJ_FILTER
    private_constant :ENV_RUNNING_PREFIX
    private_constant :ENV_ENTRYPOINT
    private_constant :BOOTSTRAP_FILE_NAMES

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

    def self.internal_env_name_only( name )
      "#{ENV_NAME_PREFIX}#{name}"
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

    def self.modified_cont_name( env )
      "#{MODIFIED_PREFIX}#{env.name}#{NAME_TAG_SEPARATOR}#{env.tag}"
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

    def initialize(cfg = Config.new)
      @cfg = cfg
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

    def run_env(env, cmd)
      cmdline = %Q{
        docker run                                                    \
               -i #{STDIN.tty? ? '-t' : ''}                           \
               --name #{self.class.modified_cont_name( env )}         \
               --hostname #{self.class.env_hostname( env, true )}     \
               #{self.class.cont_run_settings}                        \
               #{env.api_obj.id}                                      \
               "#{cmd.join(' ')}"                                     \
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

    def commit_opts(img_name)
      {
        :repo => img_name,
        :changes => ["LABEL #{ENV_LABEL}=true",
                     "ENTRYPOINT [\"#{ENV_ENTRYPOINT}\"]"]
      }
    end

    def commit_container_flat(cont, img_name)
      data_queue = Queue.new
      new_img = nil

      exporter = Thread.new do
        cont.export { |chunk| data_queue << chunk }
        data_queue << ''
      end

      importer = Thread.new do
        opts = commit_opts(img_name)
        new_img = Docker::Image.import_stream(opts) {  data_queue.pop }
      end

      exporter.join
      importer.join

      rbld_log.info("Created image #{new_img} from #{cont}")
      cont.delete( :force => true )

      new_img
    end

    def commit_container_layered(cont, img_name)
      new_img = cont.commit(commit_opts(img_name))
      rbld_log.info("Created image #{new_img} from #{cont}")
      cont.delete( :force => true )

      new_img
    end

    def self.squash_needed?(cont)
      #Different FS backends have different limitations for
      #maximum number of layers, 40 looks like small enough
      #to be supported by all possible configurations
      Docker::Image.get(cont.api_obj.info["ImageID"]).history.size >= 40
    end

    def commit_container(cont, img_name)
        self.class.squash_needed?(cont) \
          ? commit_container_flat(cont.api_obj, img_name) \
          : commit_container_layered(cont.api_obj, img_name)
    end

    def rerun_cont(cont, cmd)
        rbld_print.progress_tick

        rerun_name = self.class.internal_rerun_env_name( cont.name, cont.tag )
        new_img = commit_container( cont, rerun_name )

        rbld_print.progress_tick

        #Remove old re-run image in case it became dangling
        delete_all_dangling

        rbld_print.progress_end

        run_env( Environment.new( cont.name, cont.tag, new_img ), cmd )
    end

    def bootstrap_files
      src_path = File.join( File.dirname( __FILE__ ), "bootstrap" )
      src_path = File.expand_path( src_path )
      BOOTSTRAP_FILE_NAMES.map { |f| File.join( src_path, f ) }
    end

    def generate_dockerfile(base, is_base_file)
      if is_base_file
        base_commands = %Q{
          FROM scratch
          ADD #{base} /
        }
      else
        base_commands = %Q{
          FROM #{base}
        }
      end

      # sync after chmod is needed because of an AuFS problem described in:
      # https://github.com/docker/docker/issues/9547
      %Q{
        #{base_commands}
        LABEL #{ENV_LABEL}=true
        COPY #{BOOTSTRAP_FILE_NAMES.join(' ')} /rebuild/
        RUN chown root:root \
              /rebuild/re-build-env-prepare \
              /rebuild/re-build-bootstrap-utils \
              /rebuild/rebuild.rc && \
            chmod 700 \
              /rebuild/re-build-entry-point \
              /rebuild/re-build-env-prepare && \
            sync && \
            chmod 644 \
              /rebuild/rebuild.rc \
              /rebuild/re-build-bootstrap-utils && \
            sync && \
            /rebuild/re-build-env-prepare
        ENTRYPOINT ["/rebuild/re-build-entry-point"]
      }
    end

    def with_docker_context(basefile, dockerfile)
      tarfile_name = Dir::Tmpname.create('rbldctx') {}

      rbld_log.info("Storing context in #{tarfile_name}")

      File.open(tarfile_name, 'wb+') do |tarfile|
        Gem::Package::TarWriter.new( tarfile ) do |tar|

          files = bootstrap_files
          files << basefile unless basefile.nil?

          files.each do |file_name|
            tar.add_file(File.basename(file_name), 0640) do |t|
              IO.copy_stream(file_name, t)
            end
          end

          tar.add_file('Dockerfile', 0640) do |t|
            t.write( dockerfile )
          end

        end
      end

      File.open(tarfile_name, 'r') { |f| yield f }
    ensure
      FileUtils::rm_f( tarfile_name )
    end

    def registry
      @reg ||= Registry::API.new( @cfg.remote! )
      @reg
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

    def modify!(fullname, cmd)
      raise "Unknown environment #{fullname}" \
        unless env_idx = @all.index( fullname )

      rbld_print.progress_start 'Initializing environment'

      if cont_idx = @modified.index( fullname )
        rbld_log.info("Running container #{@modified[cont_idx].api_obj.info}")
        rerun_cont(@modified[cont_idx], cmd)
      else
        rbld_log.info("Running environment #{@all[env_idx].api_obj.info}")
        rbld_print.progress_end
        run_env(@all[env_idx], cmd)
      end
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

    def commit!(fullname, name, tag, new_tag)
      raise "Unknown environment #{fullname}" unless @all.include? fullname

      new_full_name = Environment.build_full_name( name, new_tag )
      raise "Environment #{new_full_name} already exists" \
        if @all.include? new_full_name

      if idx = @modified.index( fullname )
        cont = @modified[idx].api_obj

        rbld_log.info("Committing container #{cont.info}")
        rbld_print.progress "Creating new environment #{new_full_name}..."

        new_img_name = self.class.internal_env_name( name, new_tag )
        new_img = commit_container_flat(cont, new_img_name )
        add_environment( new_img_name, new_img )
        delete_rerun_image( name, tag )
        @modified.delete_at( idx )
      else
        raise "No changes to commit for #{fullname}"
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

    def create!(base, basefile, fullname, name, tag)
      begin
        raise "Environment #{fullname} already exists" \
          if @all.include? fullname

        rbld_print.progress "Building environment..."

        dockerfile = generate_dockerfile( base || basefile, !basefile.nil? )
        new_img = nil

        with_docker_context( basefile, dockerfile ) do |tar|
          opts = { :t => self.class.internal_env_name(name, tag),
                   :rm => true }
          new_img = Docker::Image.build_from_tar( tar, opts ) do |v|
            if ( log = JSON.parse( v ) ) && log.has_key?( "stream" )
              rbld_print.raw_trace( log["stream"] )
            end
          end
        end

        new_img_name = self.class.internal_env_name( name, tag )
        add_environment( new_img_name, new_img )

        rbld_print.progress "Successfully created #{fullname}"
      rescue Docker::Error::DockerError => msg
        new_img.remove( :force => true ) if new_img
        rbld_print.trace( msg )
        raise "Failed to create #{fullname}"
      end
    end

    def search(name, tag)
      rbld_print.progress "Searching in #{@cfg.remote!}..."

      begin
        registry.search( name, tag ).map do |e|
          Environment.build_full_name( e.name, e.tag )
        end
      rescue => msg
        rbld_print.error msg
        raise "Failed to search in #{@cfg.remote!}"
      end
    end

    def publish(fullname, name, tag)
      raise "Environment is modified, commit or checkout first" \
        if @modified.include? fullname

      if idx = @all.index( fullname )
        rbld_print.progress "Checking for collisions..."

        raise "Environment #{fullname} already published" \
              unless registry.search( name, tag ).empty?

         rbld_print.progress "Publishing on #{@cfg.remote!}..."

         begin
           registry.publish( name, tag, @all[idx].api_obj )
           rbld_print.progress "Successfully published #{fullname}"
         rescue => msg
           rbld_print.error msg
           raise "Failed to publish on #{@cfg.remote!}"
         end
      else
        raise "Unknown environment #{fullname}"
      end
    end

    def deploy!(fullname, name, tag)
      raise "Environment #{fullname} already exists" \
        if @all.include? fullname

      raise "Environment #{fullname} does not exist in the registry" \
        if registry.search( name, tag ).empty?

      rbld_print.progress "Deploying from #{@cfg.remote!}..."
      begin
       registry.deploy( name, tag ) do |img|
         img.tag( :repo => self.class.internal_env_name_only( name ),
                  :tag => tag )
         add_environment( self.class.internal_env_name( name, tag ),
                          img )
       end
       rbld_print.progress "Successfully deployed #{fullname}"
      rescue => msg
       rbld_print.error msg
       raise "Failed to deploy from #{@cfg.remote!}"
      end
    end
  end
end
