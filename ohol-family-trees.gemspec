Gem::Specification.new do |s|
  s.name        = 'ohol-family-trees'
  s.version     = '0.0.0'
  s.date        = '2019-06-07'
  s.summary     = "One Hour One Lifelog parsing and family tree generation"
  s.description = "One Hour One Lifelog parsing and family tree generation"
  s.authors     = ["wondible"]
  s.license     = 'MIT'
  s.files                 = Dir.glob("lib/**/*")
  s.test_files            = Dir.glob("{test,spec,features}/**/*")
  s.executables          << 'oneline'

  s.add_runtime_dependency "httpclient"
  s.add_runtime_dependency "stringio"
  s.add_runtime_dependency "nokogiri", ">= 1.8.5"
  s.add_runtime_dependency "ruby-graphviz"
  s.add_runtime_dependency "chunky_png"
  s.add_runtime_dependency "color"
  s.add_runtime_dependency "progress_bar"
  s.add_runtime_dependency "aws-sdk-s3", "~> 1"
  s.add_runtime_dependency "thor"
end
