require 'rubygems'

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  def cucumber_opts(cfg)

    FileUtils.mkdir_p('tmp')

    %{
      --format pretty --format rerun --out tmp/last_failed_list.txt
      --strict
      #{cfg.include?(:rerun) ? "@tmp/list_to_rerun.txt" : ""}
      #{cfg.include?(:fast) ? "-t ~@slow" : ""}
      #{cfg.include?(:slow) ? "-t @slow" : ""}
      #{cfg.include?(:local) ? "-t ~@with-registry" : ""}
      #{cfg.include?(:remote) ? "-t @with-registry" : ""}
      #{cfg.include?(:installed) ? "-p installed" : ""}
    }
  end

  Cucumber::Rake::Task.new(:test) do |t|
    t.cucumber_opts = cucumber_opts []
  end

  Cucumber::Rake::Task.new(:citest) do |t|
    cfg = []

    if ENV['rerun'] == '1'
      cfg << :rerun
    else
      cfg << :fast if ENV['fast'] == '1'
      cfg << :slow if ENV['slow'] == '1'
      cfg << :local if ENV['local'] == '1'
      cfg << :remote if ENV['remote'] == '1'
    end

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
