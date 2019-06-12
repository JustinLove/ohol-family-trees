require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/lifelog_cache'
require 'ohol-family-trees/graph'
require 'date'
require 'json'

include OHOLFamilyTrees

from_time = (Date.today - 3).to_time
to_time = (Date.today - 0).to_time

#from_time = (Time.gm(2019, 6, 3))
#to_time = (Time.gm(2019, 6, 3))
p from_time

LifelogCache::Servers.new.each do |logs|
  next unless logs.server == "bigserver2"

  lives = History.new

  lives.load_server(logs, ((from_time - 60*60*24*3)..(to_time + 60*60*24*1)))

  p lives.length
  next unless lives.length > 0

  to = lives.lives.values.last.time
  from = to - 60*60*48
#  from = from_time.to_i
#  to = to_time.to_i

  server = logs.server
  json = []

  lives.each do |l|
    if l.parent == Lifelog::NoParent
      l.lineage = l.playerid
    elsif l.parent && lives.has_key?(l.parent)
      l.lineage = lives[l.parent].lineage
    else
      p "player has no parent"
    end
  end

  lives.each do |l|
    next unless l.birth_coords
    next unless from < l.time && l.time < to
    json << l.birth_coords + [l.birth_time, l.chain, l.lineage]
  end
  File.open("output/#{server}_points.json", 'wb') do |file|
    file << JSON.pretty_generate(json)
  end
=begin
  lives.each do |life|
    if life.time > from && life.time < to && life.hash == wondible && life.name == "EVE COLIN"
      line = lives.family(life)
    end
  end
=end

end
