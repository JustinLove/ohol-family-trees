require 'lifelog'
require 'history'
require 'graph'
require 'date'
require 'json'

from_time = (Date.today - 1).to_time
to_time = (Date.today - 0).to_time

#from_time = (Date.new(2018, 11, 24)).to_time
#to_time = (Date.new(2018, 11, 26)).to_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*1)..(to_time + 60*60*24*1)))

  p lives.length
  next unless lives.length > 0

#  from = from_time.to_i
#  to = to_time.to_i

  server = dir.sub('lifeLog_', '').sub('.onehouronelife.com', '')
  json = []

  lives.each do |l|
    next unless l.birth_coords
    json << l.birth_coords + [l.name]
  end
  File.open("output/#{server}_points.json", 'wb') do |file|
    file << JSON.generate(json)
  end
=begin
  lives.each do |life|
    if life.time > from && life.time < to && life.hash == wondible && life.name == "EVE COLIN"
      line = lives.family(life)
    end
  end
=end

end
