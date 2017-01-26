Then /^it should print version information prefixed by "(.*)"$/ do |pfx|
  steps %Q{
    Then the output should contain exactly "#{pfx} #{rebuild_version}"
  }
end
