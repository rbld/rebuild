require 'docker'
require 'etc'
require 'thread'
require 'forwardable'
require_relative 'rbld_log'
require_relative 'rbld_config'
require_relative 'rbld_utils'

module Rebuild::Engine
  class NamedDockerImage
    extend Forwardable

    def_delegators :@api_obj, :id
    attr_reader :api_obj

    def initialize(name, api_obj)
      @name, @api_obj = name, api_obj
    end

    def remove!
      @api_obj.remove( name: @name.to_s )
    end

    def tag
      @api_obj.tag( repo: @name.repo,
                    tag: @name.tag )
    end

    def identity
      @name.to_s
    end
  end

  class NamedDockerContainer
    def initialize(name, api_obj)
      @name, @api_obj = name, api_obj
    end

    def remove!
      @api_obj.delete( force: true )
    end

    def flatten(img_name)
      data_queue = Queue.new
      new_img = nil

      exporter = Thread.new do
        @api_obj.export { |chunk| data_queue << chunk }
        data_queue << ''
      end

      importer = Thread.new do
        opts = commit_opts(img_name)
        new_img = Docker::Image.import_stream(opts) {  data_queue.pop }
      end

      exporter.join
      importer.join

      rbld_log.info("Created image #{new_img} from #{@api_obj}")
      remove!

      new_img
    end

    def commit(img_name)
      if squash_needed?
        flatten( img_name )
      else
        new_img = @api_obj.commit( commit_opts( img_name ) )
        rbld_log.info("Created image #{new_img} from #{@api_obj}")
        remove!
        new_img
      end
    end

    private

    def squash_needed?
      #Different FS backends have different limitations for
      #maximum number of layers, 40 looks like small enough
      #to be supported by all possible configurations
      Docker::Image.get(@api_obj.info["ImageID"]).history.size >= 40
    end

    def commit_opts(img_name)
      {repo: img_name,
       changes: ["LABEL re-build-environment=true",
                 "ENTRYPOINT [\"/rebuild/re-build-entry-point\"]"]}
    end
  end

  class NameFactory
    def initialize(env)
      @env = env
    end

    def identity
      Rebuild::Utils::FullImageName.new("re-build-env-#{@env.name}", @env.tag)
    end

    def rerun
      "re-build-rerun-#{@env.name}-rebuild-tag-#{@env.tag}:initial"
    end

    def running
      container_name(:running)
    end

    def modified
      container_name(:dirty)
    end

    def hostname
      "#{@env.name}-#{@env.tag}"
    end

    def modified_hostname
      "#{hostname}-M"
    end

    private

    def container_name(type)
      "re-build-env-#{type.to_s}-#{@env.name}-rebuild-tag-#{@env.tag}"
    end
  end

  class Environment
    def self.from_image(img_name, api_obj)
      if match = img_name.match(/^re-build-env-(.*):(.*)/)
        new( *match.captures, NamedDockerImage.new( img_name, api_obj ) )
      else
        nil
      end
    end

    def attach_container(cont_name, api_obj)
      try_attach_container(:dirty, cont_name, api_obj) ||
        try_attach_container(:running, cont_name, api_obj)
    end

    def attach_rerun_image(img_name, api_obj)
      match = img_name.match(/^re-build-rerun-(.*)-rebuild-tag-(.*):initial/)
      if my_object?( match )
        @rerun_img = NamedDockerImage.new( img_name, api_obj )
        true
      else
        false
      end
    end

    def modified?
      !@cont[:dirty].nil?
    end

    def execution_container
      @cont[:running]
    end

    def modification_container
      @cont[:dirty]
    end

    def ==(other)
      (other.name == @name) && (other.tag == @tag)
    end

    attr_reader :name, :tag, :img, :rerun_img

    private

    def initialize(name, tag, img)
      @name, @tag, @img, @cont = name, tag, img, {}
    end

    def my_object?(match)
      match && (match[1] == @name) && (match[2] == @tag)
    end

    def try_attach_container(type, cont_name, api_obj)
      match = cont_name.match(/^\/re-build-env-#{type.to_s}-(.*)-rebuild-tag-(.*)/)
      if my_object?( match )
        @cont[type] = NamedDockerContainer.new( cont_name, api_obj )
        true
      else
        false
      end
    end

    private_class_method :new
  end

  class PresentEnvironments
    include Enumerable
    extend Forwardable

    def initialize(api_module = Docker)
      @api_module = api_module
      refresh!
    end

    def refresh!
      cache_images
      attach_containers
      attach_rerun_images
    end

    def_delegators :@all, :each
    attr_reader :all

    def dangling
      rbld_images(dangling: ['true'])
    end

    def get(name)
      find { |e| e == name }
    end

    private

    def rbld_obj_filter
      { label: ["re-build-environment=true"] }
    end

    def rbld_images(filters = nil)
      filters = rbld_obj_filter.merge( filters || {} )
      @api_module::Image.all( :filters => filters.to_json )
    end

    def rbld_containers
      @api_module::Container.all( all: true, filters: rbld_obj_filter.to_json )
    end

    def cache_images
      @all = []
      rbld_images.each do |img|
        rbld_log.debug("Found docker image #{img}")
        img.info['RepoTags'].each { |tag| @all << Environment.from_image( tag, img ) }
      end
      @all.compact!
    end

    def attach_containers
      rbld_containers.each do |cont|
        rbld_log.debug("Found docker container #{cont}")
        cont.info['Names'].each do |name|
          @all.find { |e| e.attach_container( name, cont ) }
        end
      end
    end

    def attach_rerun_images
      rbld_images.each do |img|
        rbld_log.debug("Found docker image #{img}")
        img.info['RepoTags'].each do |tag|
          @all.find { |e| e.attach_rerun_image( tag, img ) }
        end
      end
    end
  end

  class EnvironmentExitCode < Rebuild::Utils::Error
    def initialize(errcode)
      @code = errcode
    end

    attr_reader :code
  end

  class UnsupportedDockerService < Rebuild::Utils::Error
    msg_prefix 'Unsupported docker service'
  end

  class EnvironmentIsModified < Rebuild::Utils::Error
    msg_prefix 'Environment is modified, commit or checkout first'
  end

  class EnvironmentNotKnown < Rebuild::Utils::Error
    msg_format 'Unknown environment %s'
  end

  class NoChangesToCommit < Rebuild::Utils::Error
    msg_format 'No changes to commit for %s'
  end

  class EnvironmentLoadFailure < Rebuild::Utils::Error
    msg_prefix 'Failed to load environment from'
  end

  class EnvironmentSaveFailure < Rebuild::Utils::Error
    msg_format 'Failed to save environment %s to %s'
  end

  class EnvironmentDeploymentFailure < Rebuild::Utils::Error
    msg_prefix 'Failed to deploy from'
  end

  class EnvironmentAlreadyExists < Rebuild::Utils::Error
    msg_format 'Environment %s already exists'
  end

  class EnvironmentNotFoundInTheRegistry < Rebuild::Utils::Error
    msg_format 'Environment %s does not exist in the registry'
  end

  class RegistrySearchFailed < Rebuild::Utils::Error
    msg_format 'Failed to search in %s'
  end

  class EnvironmentPublishCollision < Rebuild::Utils::Error
    msg_format 'Environment %s already published'
  end

  class EnvironmentPublishFailure < Rebuild::Utils::Error
    msg_prefix 'Failed to publish on'
  end

  class EnvironmentCreateFailure < Rebuild::Utils::Error
    msg_format 'Failed to create %s'
  end

  class EnvironmentFile
    def initialize(filename, docker_api = Docker)
      @filename, @docker_api = filename, docker_api
    end

    def load!
      begin
        with_gzip_reader { |gz| Docker::Image.load(gz) }
      rescue => msg
        rbld_print.trace( msg )
        raise EnvironmentLoadFailure, @filename
      end
    end

    def save!(name, identity)
      begin
        with_gzip_writer do |gz|
          Docker::Image.save_stream( identity ) { |chunk| gz.write chunk }
        end
      rescue => msg
        rbld_print.trace( msg )
        raise EnvironmentSaveFailure, [name, @filename]
      end
    end

    private

    def with_gzip_writer
      begin
        File.open(@filename, 'w') do |f|
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

  class DockerContext
    def self.from_file(file)
      base = %Q{
        FROM scratch
        ADD #{file} /
      }

      new( base, file )
    end

    def self.from_image(img)
      base = %Q{
        FROM #{img}
      }

      new( base )
    end

    def initialize(base, basefile = nil)
      @base, @basefile = base, basefile
    end

    def prepare
      tarfile_name = Dir::Tmpname.create('rbldctx') {}

      rbld_log.info("Storing context in #{tarfile_name}")

      File.open(tarfile_name, 'wb+') do |tarfile|
        Gem::Package::TarWriter.new( tarfile ) do |tar|

          files = bootstrap_file_pathnames
          files << @basefile unless @basefile.nil?

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

    private

    def bootstrap_files
      ["re-build-bootstrap-utils",
       "re-build-entry-point",
       "re-build-env-prepare",
       "rebuild.rc"]
    end

    def bootstrap_file_pathnames
      src_path = File.join( File.dirname( __FILE__ ), "bootstrap" )
      src_path = File.expand_path( src_path )
      bootstrap_files.map { |f| File.join( src_path, f ) }
    end

    def dockerfile
      # sync after chmod is needed because of an AuFS problem described in:
      # https://github.com/docker/docker/issues/9547
      %Q{
        #{@base}
        LABEL re-build-environment=true
        COPY #{bootstrap_files.join(' ')} /rebuild/
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

    private_class_method :new
  end

  class API
    extend Forwardable

    def initialize(docker_api = Docker, cfg = Rebuild::Config.new)
      @docker_api, @cfg = docker_api, cfg

      tweak_excon
      check_connectivity
      @cache = PresentEnvironments.new
    end

    def remove!(env_name)
      env = unmodified_env( env_name )
      env.img.remove!
      @cache.refresh!
    end

    def load!(filename)
      EnvironmentFile.new( filename ).load!
      # If image with the same name but another
      # ID existed before load it becomes dangling
      # and should be ditched
      @cache.dangling.each(&:remove)
      @cache.refresh!
    end

    def save(env_name, filename)
      env = existing_env( env_name )
      EnvironmentFile.new( filename ).save!(env_name, env.img.identity)
    end

    def search(env_name)
      rbld_print.progress "Searching in #{@cfg.remote!}..."

      begin
        registry.search( env_name.name, env_name.tag )
      rescue => msg
        rbld_print.trace( msg )
        raise RegistrySearchFailed, @cfg.remote!
      end
    end

    def deploy!(env_name)
      nonexisting_env(env_name)

      raise EnvironmentNotFoundInTheRegistry, env_name.full \
        if registry.search( env_name.name, env_name.tag ).empty?

      rbld_print.progress "Deploying from #{@cfg.remote!}..."

      begin
       registry.deploy( env_name.name, env_name.tag ) do |img|
         new_name = NameFactory.new(env_name).identity
         img.tag( repo: new_name.name, tag: new_name.tag )
       end
      rescue => msg
       rbld_print.trace( msg )
       raise EnvironmentDeploymentFailure, @cfg.remote!
      end

      @cache.refresh!
    end

    def publish(env_name)
      env = unmodified_env( env_name )

      rbld_print.progress "Checking for collisions..."

      raise EnvironmentPublishCollision, env_name \
         unless registry.search( env_name.name, env_name.tag ).empty?

      begin
        rbld_print.progress "Publishing on #{@cfg.remote!}..."
        registry.publish( env.name, env.tag, env.img.api_obj )
      rescue => msg
        rbld_print.trace( msg )
        raise EnvironmentPublishFailure, @cfg.remote!
      end
    end

    def run(env_name, cmd)
      env = existing_env( env_name )
      run_env_disposable( env, cmd )
      @cache.refresh!
    end

    def modify!(env_name, cmd)
      env = existing_env( env_name )

      rbld_print.progress_start 'Initializing environment'

      if env.modified?
        rbld_log.info("Running container #{env.modification_container}")
        rerun_modification_cont(env, cmd)
      else
        rbld_log.info("Running environment #{env.img}")
        rbld_print.progress_end
        run_env(env, cmd)
      end
      @cache.refresh!
    end

    def commit!(env_name, new_tag)
      env = existing_env( env_name )

      new_name = Rebuild::Utils::FullImageName.new( env_name.name, new_tag )
      nonexisting_env(new_name)

      if env.modified?
        rbld_log.info("Committing container #{env.modification_container}")
        rbld_print.progress "Creating new environment #{new_name}..."

        names = NameFactory.new( new_name )
        env.modification_container.flatten( names.identity )
        env.rerun_img.remove! if env.rerun_img
      else
        raise NoChangesToCommit, env_name.full
      end

      @cache.refresh!
    end

    def checkout!(env_name)
      env = existing_env( env_name )

      if env.modified?
        rbld_log.info("Removing container #{env.modification_container}")
        env.modification_container.remove!
      end

      env.rerun_img.remove! if env.rerun_img
      @cache.refresh!
    end

    def create!(base, basefile, env_name)
      begin
        nonexisting_env(env_name)

        rbld_print.progress "Building environment..."

        context = basefile.nil? ? DockerContext.from_image(base) \
                                : DockerContext.from_file(basefile)

        new_img = nil

        context.prepare do |tar|
          opts = { t: NameFactory.new(env_name).identity,
                   rm: true }
          new_img = Docker::Image.build_from_tar( tar, opts ) do |v|
            if ( log = JSON.parse( v ) ) && log.has_key?( "stream" )
              rbld_print.raw_trace( log["stream"] )
            end
          end
        end
      rescue Docker::Error::DockerError => msg
        new_img.remove( :force => true ) if new_img
        rbld_print.trace( msg )
        raise EnvironmentCreateFailure, "#{env_name.full}"
      end

      @cache.refresh!
    end

    def_delegator :@cache, :all, :environments

    private

    def tweak_excon
      # docker-api use Excon to issue HTTP requests
      # and default Excon timeouts which are 60 seconds
      # apply to all docker-api actions.
      # Some long-running actions like image build may
      # take more than 1 minute so timeout needs to be
      # increased
      Excon.defaults[:write_timeout] = 600
      Excon.defaults[:read_timeout] = 600
    end

    def check_connectivity
      begin
        @docker_api.validate_version!
      rescue Docker::Error::VersionError => msg
        raise UnsupportedDockerService, msg
      end
    end

    def registry
      @registry ||= Rebuild::Registry::API.new( @cfg.remote! )
      @registry
    end

    def run_external(cmdline)
      rbld_log.info("Executing external command #{cmdline}")
      system( cmdline )
      errcode = $?.exitstatus
      rbld_log.info( "External command returned with code #{errcode}" )
      raise Rebuild::Engine::EnvironmentExitCode, errcode if errcode != 0
    end

    def run_settings(env, cmd, opts = {})
       %Q{ -i #{STDIN.tty? ? '-t' : ''}                               \
           -v #{Dir.home}:#{Dir.home}                                 \
           -e REBUILD_USER_ID=#{Process.uid}                          \
           -e REBUILD_GROUP_ID=#{Process.gid}                         \
           -e REBUILD_USER_NAME=#{Etc.getlogin}                       \
           -e REBUILD_GROUP_NAME=#{Etc.getgrgid(Process.gid)[:name]}  \
           -e REBUILD_USER_HOME=#{Dir.home}                           \
           -e REBUILD_PWD=#{Dir.pwd}                                  \
           --security-opt label:disable                               \
           #{opts[:rerun] ? env.rerun_img.id : env.img.id}            \
           "#{cmd.join(' ')}"                                         \
       }
    end

    def run_env_disposable(env, cmd)
      env.execution_container.remove! if env.execution_container
      names = NameFactory.new(env)

      cmdline = %Q{
        docker run                           \
             --rm                            \
             --name #{names.running}         \
             --hostname #{names.hostname}    \
             #{run_settings( env, cmd )}     \
      }

      run_external( cmdline )
    end

    def run_env(env, cmd, opts = {})
      names = NameFactory.new(env)

      cmdline = %Q{
        docker run                                     \
               --name #{names.modified}                \
               --hostname #{names.modified_hostname}   \
               #{run_settings( env, cmd, opts )}       \
      }

      run_external( cmdline )
    end

    def rerun_modification_cont(env, cmd)
      rbld_print.progress_tick

      names = NameFactory.new( env )
      new_img = env.modification_container.commit( names.rerun )

      rbld_print.progress_tick

      #Remove old re-run image in case it became dangling
      @cache.dangling.each(&:remove)

      rbld_print.progress_end

      @cache.refresh!

      run_env( @cache.get(env), cmd, rerun: true )
    end

    def existing_env(name)
      env = @cache.get(name)
      raise EnvironmentNotKnown, name.full unless env
      env
    end

    def unmodified_env(name)
      env = existing_env( name )
      raise EnvironmentIsModified if env.modified?
      env
    end

    def nonexisting_env(name)
      raise EnvironmentAlreadyExists, name.full if @cache.get(name)
    end
  end
end
