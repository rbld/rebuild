require 'docker'
require 'etc'
require 'thread'
require 'forwardable'
require 'os'
require_relative 'rbld_log'
require_relative 'rbld_config'
require_relative 'rbld_utils'
require_relative 'rbld_print'
require_relative 'rbld_reg_docker'
require_relative 'rbld_reg_dockerhub'
require_relative 'rbld_reg_fs'
require_relative 'rbld_fileops'

module Rebuild::Engine
  extend Rebuild::Utils::Errors

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
      {repo: img_name.repo,
       tag: img_name.tag,
       changes: ["LABEL re-build-environment=true",
                 "ENTRYPOINT [\"/rebuild/re-build-entry-point\"]"]}
    end
  end

  class NameFactory
    def initialize(env)
      @env = env
    end

    def identity
      Rebuild::Utils::FullImageName.new("rbe-#{@env.name}", @env.tag)
    end

    def rerun
      Rebuild::Utils::FullImageName.new("rbr-#{@env.name}-rt-#{@env.tag}", 'initial')
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
      "rbe-#{type.to_s.chars.first}-#{@env.name}-rt-#{@env.tag}"
    end
  end

  class Environment
    def self.from_image(img_name, api_obj)
      if match = img_name.match(/^rbe-(.*):(.*)/)
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
      match = img_name.match(/^rbr-(.*)-rt-(.*):initial/)
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
      match = cont_name.match(/^\/rbe-#{type.to_s.chars.first}-(.*)-rt-(.*)/)
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

    def repo_tags(img)
      img.info['RepoTags'] || []
    end

    def cache_images
      @all = []
      rbld_images.each do |img|
        rbld_log.debug("Found docker image #{img}")
        repo_tags( img ).each { |tag| @all << Environment.from_image( tag, img ) }
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
        repo_tags( img ).each do |tag|
          @all.find { |e| e.attach_rerun_image( tag, img ) }
        end
      end
    end
  end

  rebuild_errors \
   UnsupportedDockerService: 'Unsupported docker service: %s',
   InaccessibleDockerService: 'Unable to reach the docker engine',
   EnvironmentIsModified: 'Environment is modified, commit or checkout first',
   EnvironmentNotKnown: 'Unknown environment %s',
   NoChangesToCommit: 'No changes to commit for %s',
   EnvironmentDeploymentFailure: 'Failed to deploy from %s',
   EnvironmentAlreadyExists: 'Environment %s already exists',
   EnvironmentNotFoundInTheRegistry: 'Environment %s does not exist in the registry',
   RegistrySearchFailed: 'Failed to search in %s',
   EnvironmentPublishCollision: 'Environment %s already published',
   EnvironmentPublishFailure: 'Failed to publish on %s',
   EnvironmentCreateFailure: 'Failed to create %s'

  class DockerContext
    def self.from_file(file)
      base = %Q{
        FROM scratch
        ADD #{File.basename( file )} /
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
      src_path = File.join( __dir__, "bootstrap" )
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
            }.squeeze(' ')
    end

    private_class_method :new
  end

  class RunSettings
    def initialize
      @group_name = get_group_name
      @user_name = Etc.getlogin
      @home = get_home
      @pwd = get_pwd
      @uid = get_uid
      @gid = get_gid
    end

    attr_reader :group_name, :home, :pwd, :user_name, :uid, :gid

    private

    def get_group_name
      if group_info = Etc.getgrgid(Process.gid)
        group_info[:name]
      else
        Etc.getlogin
      end
    end

    def get_home
      OS.windows? ? "/home/#{Etc.getlogin}" : Dir.home
    end

    def get_pwd
      host_home = ( OS.mac? || OS.windows? ) ? /#{Dir.home}/i : Dir.home
      pwd = Dir.pwd.sub(host_home, home)
      rbld_log.info( "Deducing environment PWD: #{Dir.pwd}, #{host_home}, #{home} ==> #{pwd}" )
      pwd
    end

    def macos_docker_machine?
      OS.mac? && ENV['DOCKER_MACHINE_NAME']
    end

    def get_uid
      case
      when OS.windows?
        1000
      when macos_docker_machine?
        0
      else
        Process.uid
      end
    end

    def get_gid
      case
      when OS.windows?
        1000
      when macos_docker_machine?
        0
      else
        Process.gid
      end
    end
  end

  class API
    extend Forwardable

    def initialize(docker_api = Docker, cfg = Rebuild::Config.new)
      @docker_api, @cfg = docker_api, cfg

      tweak_excon
      tweak_docker_url
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
      rbld_print.progress "Searching in #{@cfg.remote!.path}..."

      begin
        registry.search( env_name.name, env_name.tag )
      rescue => msg
        rbld_print.trace( msg )
        raise RegistrySearchFailed, @cfg.remote!.path
      end
    end

    def deploy!(env_name)
      nonexisting_env(env_name)

      raise EnvironmentNotFoundInTheRegistry, env_name.full \
        if registry.search( env_name.name, env_name.tag ).empty?

      rbld_print.progress "Deploying from #{@cfg.remote!.path}..."

      begin
       registry.deploy( env_name.name, env_name.tag ) do |img|
         new_name = NameFactory.new(env_name).identity
         img.tag( repo: new_name.name, tag: new_name.tag )
       end
      rescue => msg
       rbld_print.trace( msg )
       raise EnvironmentDeploymentFailure, @cfg.remote!.path
      end

      @cache.refresh!
    end

    def publish(env_name)
      env = unmodified_env( env_name )

      rbld_print.progress "Checking for collisions..."

      raise EnvironmentPublishCollision, env_name \
         unless registry.search( env_name.name, env_name.tag ).empty?

      begin
        rbld_print.progress "Publishing on #{@cfg.remote!.path}..."
        registry.publish( env.name, env.tag, env.img )
      rescue => msg
        rbld_print.trace( msg )
        raise EnvironmentPublishFailure, @cfg.remote!.path
      end
    end

    def run(env_name, cmd, runopts = {})
      env = existing_env( env_name )
      run_env_disposable( env, cmd, runopts )
      @cache.refresh!
      @errno
    end

    def modify!(env_name, cmd, runopts = {})
      env = existing_env( env_name )

      rbld_print.progress_start 'Initializing environment'

      if env.modified?
        rbld_log.info("Running container #{env.modification_container}")
        rerun_modification_cont(env, cmd, runopts)
      else
        rbld_log.info("Running environment #{env.img}")
        rbld_print.progress_end
        run_env(env, cmd, runopts)
      end
      @cache.refresh!
      @errno
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
            begin
              if ( log = JSON.parse( v ) ) && log.has_key?( "stream" )
                rbld_print.raw_trace( log["stream"] )
              end
            rescue
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

    def tweak_docker_url
      # Default unix pipe does not work with Docker for Windows
      # Use TCP connection instead
      Docker.url = 'tcp://127.0.0.1:2375' if OS.windows?
    end

    def check_connectivity
      @docker_api.validate_version!

      rescue Docker::Error::VersionError => msg
        rbld_log.fatal( msg )
        raise UnsupportedDockerService, msg
      rescue => msg
        rbld_log.fatal( msg )
        raise InaccessibleDockerService
    end

    def registry
      return @registry if @registry

      case @cfg.remote!.type
      when 'docker'
        reg_module = Rebuild::Registry::Docker
      when 'dockerhub'
        reg_module = Rebuild::Registry::DockerHub
      when 'rebuild'
        reg_module = Rebuild::Registry::FS
      else
        raise "Remote type #{@cfg.remote!.type} is unknown"
      end

      @registry = reg_module::API.new( @cfg.remote!.path )
    end

    def run_external(cmdline)
      rbld_log.info("Executing external command #{cmdline.squeeze( ' ' )}")
      system( cmdline )
      @errno = $?.exitstatus
      rbld_log.info( "External command returned with code #{@errno}" )
    end

    def run_user_group_name
      if group_info = Etc.getgrgid(Process.gid)
        group_info[:name]
      else
        Etc.getlogin
      end
    end

    def trace_run_settings
      if ENV['RBLD_BOOTSTRAP_TRACE'] && ENV['RBLD_BOOTSTRAP_TRACE'] == '1'
        '-e REBUILD_TRACE=1'
      else
        ''
      end
    end

    def run_settings(env, cmd, opts = {})
      rs = RunSettings.new
      %Q{ -i #{STDIN.tty? ? '-t' : ''}                      \
          -v #{Dir.home}:#{rs.home}                         \
          -e REBUILD_USER_ID=#{rs.uid}                      \
          -e REBUILD_GROUP_ID=#{rs.gid}                     \
          -e REBUILD_USER_NAME=#{rs.user_name}              \
          -e REBUILD_GROUP_NAME=#{rs.group_name}            \
          -e REBUILD_USER_HOME=#{rs.home}                   \
          -e REBUILD_PWD=#{rs.pwd}                          \
          --security-opt label:disable                      \
          #{trace_run_settings}                             \
          #{opts[:privileged] ? "--privileged" : ""}        \
          #{opts[:rerun] ? env.rerun_img.id : env.img.id}   \
          "#{cmd.join(' ')}"                                \
      }
    end

    def run_env_disposable(env, cmd, runopts)
      env.execution_container.remove! if env.execution_container
      names = NameFactory.new(env)

      cmdline = %Q{
        docker run                                    \
             --rm                                     \
             --name #{names.running}                  \
             --hostname #{names.hostname}             \
             #{run_settings( env, cmd, runopts )}     \
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

    def rerun_modification_cont(env, cmd, opts = {})
      rbld_print.progress_tick

      names = NameFactory.new( env )
      new_img = env.modification_container.commit( names.rerun )

      rbld_print.progress_tick

      #Remove old re-run image in case it became dangling
      @cache.dangling.each(&:remove)

      rbld_print.progress_end

      @cache.refresh!

      run_env( @cache.get(env), cmd, opts.merge(rerun: true) )
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
