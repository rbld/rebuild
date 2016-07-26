require 'aruba/cucumber'
require_relative 'test_constants.rb'

Aruba.configure do |config|
  config.exit_timeout = 600
end

include RebuildTestConstants
