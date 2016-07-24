Then /^the output should be empty$/ do
  steps %Q{
    Then the output should contain exactly:
      """
      """
  }
end
