require 'lifelog'
require 'history'
require 'graph'
require 'date'
require 'json'

from_time = (Date.today - 30).to_time
to_time = (Date.today - 0).to_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*1)..(to_time + 60*60*24*1)))

  p lives.length
  next unless lives.length > 0

  from = from_time.to_i
  to = to_time.to_i

  server = dir.sub('lifeLog_', '').sub('.onehouronelife.com', '')
  json = []

  wondible = 'e45aa4e489b35b6b0fd9f59f0049c688237a9a86'

  lives.each do |life|
    if life.time > from && life.time < to && life.hash == wondible
      json << life.birth_coords
    end
  end

  File.open("output/#{server}_#{from_time.to_date}_#{to_time.to_date}.json", 'wb') do |file|
    file << JSON.generate(json)
  end
end
