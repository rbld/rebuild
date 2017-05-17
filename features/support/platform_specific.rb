require 'os'

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
