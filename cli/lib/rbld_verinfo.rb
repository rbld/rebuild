module Rebuild
  module Version
    def self.retrieve_info
      git_ver_script = File.expand_path("../../../tools/version.rb", __FILE__)
      if File.exists?( git_ver_script )
        require git_ver_script
        rbld_version
      else
        File.read(File.expand_path("../data/version", __FILE__))
      end
    end

    private_class_method :retrieve_info

    def self.info
      @ver ||= retrieve_info
    end
  end
end
