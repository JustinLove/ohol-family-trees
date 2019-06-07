require 'lifelog'
require 'history'
require 'graph'
require 'date'
require 'json'

from_time = (Date.today - 2).to_time
to_time = (Date.today - 0).to_time

#from_time = (Time.gm(2019, 6, 3))
#to_time = (Time.gm(2019, 6, 3))
p from_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")
  next unless dir.match("bigserver2")

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*3)..(to_time + 60*60*24*1)))
  #lives.load_dir("cache/"+dir, ((from_time)..(to_time)))

  p lives.length
  next unless lives.length > 0

  to = lives.lives.values.last.time
  from = to - 60*60*24
#  from = from_time.to_i
#  to = to_time.to_i

  server = dir.sub('lifeLog_', '').sub('.onehouronelife.com', '')
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
