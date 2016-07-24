module KnowsRebuildConf
  def rebuild_conf
    @rebuild_conf ||= RebuildConfFile.new
  end
end

World(KnowsRebuildConf)
