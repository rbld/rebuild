Before do
  cfg_file=rebuild_conf.path_name
  cfg_file_backup=cfg_file + ".backup"
  %x(sudo cp -p #{cfg_file} #{cfg_file_backup})
  fail "Failed to backup config file #{cfg_file} -> #{cfg_file_backup}" unless $?.success?
end

After do
  cfg_file=rebuild_conf.path_name
  cfg_file_backup=cfg_file + ".backup"
  %x(sudo mv #{cfg_file_backup} #{cfg_file})
  fail "Failed to restore config file #{cfg_file_backup} -> #{cfg_file}" unless $?.success?
end
