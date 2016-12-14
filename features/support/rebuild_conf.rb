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

  def set_registry(url)
    fill %Q{
        REMOTE_NAME=origin
        REMOTE_origin="#{url}"
      }
  end
end
