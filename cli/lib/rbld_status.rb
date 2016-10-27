#!/usr/bin/env ruby

require_relative 'rbld_envmgr'

module Rebuild
  class RbldStatusCommand < Command
    legacy_usage_implementation :status
    legacy_run_implementation :status
  end
end
