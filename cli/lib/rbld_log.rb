require 'logger-better'
require 'docker'

module Rebuild
  module Logger
    def rbld_log
      if @rbld_logger.nil?
        if ENV['RBLD_LOG_LEVEL'].nil?
          @rbld_logger = NullLogger.new
        else
          @rbld_logger = ::Logger::Better.new ENV['RBLD_LOG_FILE'] || STDOUT
          @rbld_logger.level = ENV['RBLD_LOG_LEVEL'].to_sym
        end
      end
      @rbld_logger
    end
  end
end

include Rebuild::Logger

#Hook up docker API logs
#for the higher log level
if ENV['RBLD_LOG_LEVEL'] && (ENV['RBLD_LOG_LEVEL'].to_sym == :debug)
    Docker::logger = rbld_log
end
