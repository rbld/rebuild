require 'logger-better'

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
