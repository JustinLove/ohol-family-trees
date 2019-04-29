require 'lifelog'
require 'history'
require 'graph'
require 'date'

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")
  #next unless dir.match("server7")

  lives = History.new

  lives.load_dir("cache/"+dir)

  p dir
  p lives.length
  p lives.epoch
end
