#!/usr/bin/env ruby

require_relative '../features/support/dockerhub'
require_relative '../cli/lib/rbld_reg_dockerhub'
require_relative '../features/support/test_constants'

def cred(name)
  ENV["RBLD_CREDENTIAL_#{name.upcase}"]
end

path = Class.new.extend(RebuildTestConstants).dockerhub_namespace

dh_registry = Rebuild::Registry::DockerHub::API.new(path)
dh = Rebuild::DockerHub.new(cred('username'), cred('password'))

repos = dh_registry.search_repos
dh.kill_repos(repos)
