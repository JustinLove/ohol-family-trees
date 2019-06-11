Gem::Specification.new do |s|
  s.name        = 'ohol-family-trees'
  s.version     = '0.0.0'
  s.date        = '2019-06-07'
  s.summary     = "One Hour One Lifelog parsing and family tree generation"
  s.description = "One Hour One Lifelog parsing and family tree generation"
  s.authors     = ["wondible"]
  s.license     = 'MIT'
  s.files       = [
    "lib/fetch.rb",
    "lib/graph.rb",
    "lib/history.rb",
    "lib/lifelog.rb",
    "lib/monument.rb",
    "lib/wraper.html",
  ]

  s.add_runtime_dependency "httpclient"
  s.add_runtime_dependency "nokogiri", ">= 1.8.5"
  s.add_runtime_dependency "ruby-graphviz"
  s.add_runtime_dependency "color"
  s.add_runtime_dependency "progress_bar"
end