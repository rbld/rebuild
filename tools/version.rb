def rbld_version
  v = %x(git describe --tags --dirty)
  if m = v.match(/^v([0-9]+)\.([0-9]+)\.([0-9]+)(.*)$/)
    "#{m[1]}.#{m[2]}.#{m[3]}#{m[4].gsub('-', '.')}"
  else
    raise "Failed to parse version string #{v}"
  end
end
