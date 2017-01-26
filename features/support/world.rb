module KnowsRebuildConf
  def rebuild_conf
    @rebuild_conf ||= RebuildConfFile.new
  end
end

module KnowsRebuildVersion
  if ENV['TEST_WORKING_COPY'] == '1'
    require_relative '../../tools/version.rb'
    alias get_version rbld_version
  else
    def get_version
      file = %x(gem list -lq rbld).split("\n").first
      file.match( /^rbld \((.*)\)$/ ).captures.first
    end
  end

  def rebuild_version
    @version ||= get_version
  end
end

World(KnowsRebuildConf)
World(KnowsRebuildVersion)
