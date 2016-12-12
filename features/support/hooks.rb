Before do
  cfg_file=rebuild_conf.path_name
  cfg_file_backup=cfg_file + ".backup"
  FileUtils.cp(cfg_file, cfg_file_backup) if File.exist?(cfg_file)
end

After do
  cfg_file=rebuild_conf.path_name
  cfg_file_backup=cfg_file + ".backup"
  FileUtils.mv(cfg_file_backup, cfg_file) if File.exist?(cfg_file_backup)
end
