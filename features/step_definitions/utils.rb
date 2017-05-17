Given(/^I successfully run `(.*)` for (\d+ times)$/) do |cmd, i|
  i.times do
    steps %Q{
      Given I successfully run `#{cmd}`
    }
  end
end

Given(/^sample source code from "([^"]*)"$/) do |src_dir|
  FileUtils.cp_r(File.join(tests_root_dir, src_dir), tests_work_dir)
end

Given (/^I send signal "([^"]*)" to rbld application$/) do |sig_name|
  # To simulate running rbld CLI in background
  # we configure a dummy dockerhub remote and
  # and try to publish an environment.
  # In this case rbld will ask for credentials
  # and wait for user input.

  steps %Q{
    Given I set the environment variables to:
      | variable                 | value |
      | RBLD_CREDENTIAL_USERNAME |       |
    Given the default aruba exit timeout is 60 seconds
    And I wait 5 seconds for a command to start up
    And remote registry type is "dockerhub"
    And remote registry path is "rbld-dummy/environments-dummy"
    And existing environment test-env
    And I run `rbld publish test-env` in background
    And I send the signal "#{sig_name}" to the command "rbld publish test-env"
    Then the exit status should not be 0
  }
end

Given(/^I use default rbld CLI configuration$/) do
  RebuildConfFile.new.revert_to_default
end
