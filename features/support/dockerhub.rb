require 'net/http'
require 'uri'

module Rebuild

class DockerHub

  def kill_repos(list)
    list.each &method(:kill_repo)
  end

  def kill_repo(path)
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

  def initialize(username, password)
    @user, @pass = username, password
  end

  private

  def issue_kill_repo_request(uri_string)
    uri = URI.parse(uri_string)
    request = Net::HTTP::Delete.new(uri)
    request.basic_auth(@user, @pass)
    request.content_type = 'application/json'
    request['Accept'] = 'application/json'

    opts = { use_ssl: uri.scheme == 'https' }

    Net::HTTP.start(uri.hostname, uri.port, opts) do |http|
      http.request(request)
    end
  end
end

end
