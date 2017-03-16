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
