#!/usr/bin/env ruby

module Rebuild
  class RbldRmCommand < Command
    legacy_usage_implementation :rm
    legacy_run_implementation :rm
  end
end
