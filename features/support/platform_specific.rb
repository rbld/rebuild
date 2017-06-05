require 'os'
require 'docker-api'

def skip_this(scenario)
  if Cucumber::VERSION < '2'
    scenario.skip_invoke!
  else
    skip_this_scenario
  end
end

Before( '@skip-on-windows' ) do |scenario|
  skip_this( scenario ) if OS.windows?
end

def parse_version(v)
  Gem::Version.new( v )
end

Docker.url = 'tcp://127.0.0.1:2375' if OS.windows?

def docker_version
  parse_version( Docker.info['ServerVersion'].partition('-').first )
end

def skip_on_old_docker( scenario, v )
    skip_this( scenario ) if docker_version < parse_version( v )
end

Before( '@skip-on-docker-before-1-12-0' ) do |scenario|
  skip_on_old_docker( scenario, '1.12.0' )
end
