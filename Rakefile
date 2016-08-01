require 'rubygems'

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  def cucumber_opts
    %{
      --format pretty
      #{ENV['fast'] == '1' ? "-t ~@slow" : ""}
      #{ENV['installed'] == '1' ? "-p installed" : ""}
    }
  end

  Cucumber::Rake::Task.new(:test) do |t|
    t.cucumber_opts = cucumber_opts
  end

  Cucumber::Rake::Task.new(:fasttest) do |t|
    ENV['fast'] = '1'
    t.cucumber_opts = cucumber_opts
  end

rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end
