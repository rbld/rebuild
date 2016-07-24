class RebuildConfFile
  def initialize
    require 'ptools'
    require 'pathname'

    rbld_path = File.which("rbld")
    fail 'Failed to find rbld executable' if rbld_path.to_s.empty?

    @path_name = Pathname(rbld_path).dirname().to_path() + "/../etc/rebuild.conf"
  end

  attr_reader :path_name

  def fill(content)
    %x(sudo tee #{path_name}<<END
#{content}
END)
    fail "Configuration file #{path_name} population failed" unless $?.success?
  end

  def set_registry(url)
    fill %Q{
        REMOTE_NAME=origin
        REMOTE_origin="#{url}"
      }
  end
end
