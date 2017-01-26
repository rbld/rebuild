require_relative 'tools/version'

Gem::Specification.new do |s|
  s.name        = 'rbld'
  s.version     = rbld_version
  s.author      = 'Dmitry Fleytman'
  s.description = 'Zero-dependency, reproducible build environments'
  s.summary     = "rbld-#{s.version}"
  s.email       = 'rbld-devel@rbld.io'
  s.license     = 'Apache-2.0'
  s.homepage    = 'http://rbld.io/'
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.0.0'

  s.add_runtime_dependency 'colorize', '~> 0.8.1'
  s.add_runtime_dependency 'logger-better', '~> 0.2.1'
  s.add_runtime_dependency 'docker-api', '~> 1.32', '>= 1.32.1'
  s.add_runtime_dependency 'docker_registry2', '~> 0.3.0'
  s.add_runtime_dependency 'parseconfig', '~> 1.0', '>= 1.0.8'
  s.add_runtime_dependency 'require_all', '~> 1.3', '>= 1.3.3'
  s.add_runtime_dependency 'os', '~> 0.9', '>= 0.9.6'
  # rake must be in runtime dependencies for proper gem installation
  # (to process tools/rebuild-conf/Rakefile)
  s.add_runtime_dependency 'rake', '~> 11.2', '>= 11.2.2' #needed for install

  s.add_development_dependency 'travis', '~> 1.8', '>= 1.8.2'
  s.add_development_dependency 'aruba', '~> 0.14.1', '>= 0.14.0'
  s.add_development_dependency 'ptools', '~> 1.3', '>= 1.3.3'
  s.add_development_dependency 'retriable', '~> 2.1', '>= 2.1.0'
  s.add_development_dependency 'rspec', '~> 3.5', '>= 3.5.0'

  lib_files = `git ls-files -- cli/lib`.split("\n")
  bin_files = ['cli/bin/rbld']
  ver_path = 'cli/lib/data/'
  ver_file = ver_path + 'version'

  FileUtils.rm_rf(ver_path)
  FileUtils.mkdir_p(ver_path)
  File.write(ver_file, s.version)

  s.files            = lib_files + bin_files + [ ver_file ]
  s.executables      = bin_files.map{ |f| File.basename(f) }
  s.require_path     = 'cli/lib'
  s.bindir           = 'cli/bin'

  s.post_install_message = 'Thanks for installing rebuild. Run `rbld help` for CLI reference.'
  s.extensions = %w[tools/rebuild-conf/Rakefile]
end
