require 'ohol-family-trees/monument'
require 'ohol-family-trees/monument_cache'
require 'json'

include OHOLFamilyTrees

MonumentCache::Servers.new.each do |logfile|
  p logfile.path

  server = logfile.server

  monuments = Monument.load_log(logfile)
  #p monuments

  json = []

  monuments.each do |monument|
    json << [monument.x, monument.y, monument.date, monument.server]
  end

  File.open("output/#{server}_monuments.json", 'wb') do |file|
    file << JSON.generate(json)
  end
end
