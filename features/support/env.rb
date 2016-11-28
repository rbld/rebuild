require 'aruba/cucumber'
require_relative 'test_constants'

Aruba.configure do |config|
  config.exit_timeout = 600
end

include RebuildTestConstants
