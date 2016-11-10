Given(/^I successfully run `(.*)` for (\d+ times)$/) do |cmd, i|
  i.times do
    steps %Q{
      Given I successfully run `#{cmd}`
    }
  end
end
