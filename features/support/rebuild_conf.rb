class RebuildConfFile
  def initialize
    require 'ptools'
    require 'pathname'

    @conf_dir = File.join( Dir.home, '.rbld')
    @path_name = File.join( @conf_dir, 'rebuild.conf' )
  end

  attr_reader :path_name

  def fill(content)
    FileUtils.mkdir_p( @conf_dir )
    open(@path_name, 'w') { |f| f.write(content) }
  end

  def set_registry(type, path)
    fill %Q{
        REMOTE_NAME=origin
        REMOTE_TYPE_origin="#{type}"
        REMOTE_origin="#{path}"
      }
  end

  def revert_to_default
    cmdline = "rake -f #{rebuild_conf_rakefile} force"
    output = %x(#{cmdline})
    fail "Failed to run \"#{cmdline}\": #{output}" unless $?.success?
  end
end
