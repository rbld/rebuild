require 'singleton'
require 'securerandom'
require 'net/http'
require 'uri'

class BaseDockerHubRegistry
  private

  def cred(name)
    ENV["RBLD_CREDENTIAL_#{name.upcase}"]
  end

  def issue_kill_repo_request(uri_string)
    uri = URI.parse(uri_string)
    request = Net::HTTP::Delete.new(uri)
    request.basic_auth(cred('username'), cred('password'))
    request.content_type = 'application/json'
    request["Accept"] = 'application/json'

    req_options = { use_ssl: uri.scheme == "https" }

    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def kill_dockerhub_repo(path)
    begin
      puts "Deleting DockerHub repository #{path}..."

      uri = "https://index.docker.io/v1/repositories/#{path}"

      response = issue_kill_repo_request(uri)

      response = issue_kill_repo_request(response['location']) \
        if response.kind_of? Net::HTTPRedirection

      response.value \
        unless response.kind_of? Net::HTTPNotFound

    rescue => e
      STDERR.puts "Removal of #{path} repo failed: #{e.msg}"
    end
  end

  def create_registry
    @registry_path = "#{@registry_base}-#{SecureRandom.uuid}"
    @dockerhub_repos << @registry_path
    @rebuild_conf.set_registry(:dockerhub,  @registry_path)
  end

  def recreate_registry
    create_registry
  end

  public

  def initialize(name)
    @registry_base = "#{dockerhub_namespace}/ci-#{name}"
    @rebuild_conf = RebuildConfFile.new

    @dockerhub_repos = []
    at_exit do
      puts
      puts "Running post-test cleanups:"
      @dockerhub_repos.each { |r| kill_dockerhub_repo(r) }
    end

    create_registry
  end

  def populate_registry
    ["1:v001", "1:v002", "2:v001"].each do |suffix|
      env = RebuildEnvironment.new("test-env#{suffix}")
      env.ensure_exists
      env.ensure_not_modified
      env.ensure_published
    end
  end

  def use
    @rebuild_conf.set_registry(:dockerhub,  @registry_path)
  end
end

class UnaccessibleDockerHubRegistry
  include Singleton

  def use
    RebuildConfFile.new.set_registry(:dockerhub, 'rbld-no-namespace/rbld-no-repo')
    yield 'RBLD_OVERRIDE_INDEX_ENDPOINT', 'unaccessible.rbld.io'
  end
end

class PopulatedDockerHubRegistry < BaseDockerHubRegistry
  include Singleton

  def initialize
    super('populated')
    populate_registry()
  end
end

class EmptyDockerHubRegistry < BaseDockerHubRegistry
  include Singleton

  def initialize
    super('empty')
  end

  def use
    recreate_registry
    super
  end
end
