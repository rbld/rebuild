module RebuildTestConstants
  def test_env_base
    "alpine:3.4"
  end

  def registry_image_name
    "registry:2.5.1"
  end

  def fs_registry_location
    unless @fs_reg_location
      Aruba.configure do |c|
        @fs_reg_location = File.expand_path( File.join(c.root_directory, 'test_remotes') )
      end
    end
    @fs_reg_location
  end

  def dockerhub_namespace
    'rebuildci'
  end
end
