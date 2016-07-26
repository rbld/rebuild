Then /^it should (pass|fail) with empty output$/ do |result|
steps %Q{
  Then it should #{result} with exactly:
    """
    """
}
end
