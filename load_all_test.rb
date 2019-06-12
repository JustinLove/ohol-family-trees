require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/lifelog_cache'
require 'ohol-family-trees/graph'
require 'date'

include OHOLFamilyTrees

LifelogCache::Servers.new.each do |logs|
  #next unless dir.match("server7")

  lives = History.new

  lives.load_server(logs)

  p logs.server
  p lives.length
  p lives.epoch
end
