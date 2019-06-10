require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/graph'
require 'date'

include OHOLFamilyTrees

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")
  #next unless dir.match("server7")

  lives = History.new

  lives.load_dir("cache/"+dir)

  p dir
  p lives.length
  p lives.epoch
end
