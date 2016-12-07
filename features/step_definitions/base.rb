Given /^existing base file (.*\.tar)$/ do |basefile|

  cidfile = basefile + ".cid"

  steps %Q{
    Given I successfully run `docker run --cidfile #{cidfile} #{test_env_base} echo -n`
  }

  cid = File.read(expand_path(cidfile))

  steps %Q{
    And I successfully run `docker export --output #{basefile} #{cid}`
    And I successfully run `docker rm #{cid}`
  }
end

Given /^(?:a )?local docker image (.*)$/ do |img_name|
  steps %Q{
    Given I successfully run `docker pull #{test_env_base}`
    And I successfully run `docker tag #{test_env_base} #{img_name}`
  }
end
