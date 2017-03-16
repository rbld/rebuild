require 'colorize'

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

  def tests_work_dir
    unless @work_dir
      Aruba.configure { |c| @work_dir = c.working_directory }
    end
    @work_dir
  end

  def tests_root_dir
    unless @root_dir
      Aruba.configure { |c| @root_dir = c.root_directory }
    end
    @root_dir
  end

  def dockerhub_namespace
    'rebuildci'
  end

  def known_registry_classes
    {
      docker:     { empty:        EmptyDockerRegistry,
                    populated:    PopulatedDockerRegistry,
                    unaccessible: UnaccessibleDockerRegistry },
      rebuild:    { empty:        EmptyFSRegistry,
                    populated:    PopulatedFSRegistry,
                    unaccessible: UnaccessibleFSRegistry },
      dockerhub:  { empty:        EmptyDockerHubRegistry,
                    populated:    PopulatedDockerHubRegistry,
                    unaccessible: UnaccessibleDockerHubRegistry }
    }
  end

  def registry_type
    unless @reg_type
      env = ENV['registry_type']
      @reg_type = (env || 'rebuild').to_sym
    end
    @reg_type
  end

  def registry_classes
    @reg_classes ||= known_registry_classes[registry_type]
  end
end
