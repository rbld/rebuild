require 'rubygems'

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  def cucumber_opts(cfg)
    %{
      --format pretty
      --strict
      #{cfg.include?(:fast) ? "-t ~@slow" : ""}
      #{cfg.include?(:slow) ? "-t @slow" : ""}
      #{cfg.include?(:installed) ? "-p installed" : ""}
    }
  end

  Cucumber::Rake::Task.new(:test) do |t|
    t.cucumber_opts = cucumber_opts []
  end

  Cucumber::Rake::Task.new(:citest) do |t|
    cfg = []
    cfg << :fast if ENV['fast'] == '1'
    cfg << :slow if ENV['slow'] == '1'
    cfg << :installed if ENV['installed'] == '1'

    t.cucumber_opts = cucumber_opts cfg
  end

  Cucumber::Rake::Task.new(:fasttest) do |t|
    t.cucumber_opts = cucumber_opts [:fast]
  end

  Cucumber::Rake::Task.new(:slowtest) do |t|
    t.cucumber_opts = cucumber_opts [:slow]
  end

rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :lint do
    begin
      require 'travis/yaml'

      puts 'Linting .travis.yml ... No output is good!'
      Travis::Yaml.parse! File.read('.travis.yml')
    rescue LoadError => e
      $stderr.puts "Failed to lint .travis.yml: #{e.message}"
    end
end
