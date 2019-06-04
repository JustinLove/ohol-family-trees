require 'lifelog'
require 'history'
require 'graph'
require 'date'
require 'csv'
require 'json'

wondible = 'e45aa4e489b35b6b0fd9f59f0049c688237a9a86'
from_time = (Date.today - 2).to_time
to_time = (Date.today - 0).to_time

known_players = {}
CSV.foreach("known-players.csv") do |row|
  known_players[row[0]] = row[1] #if row[1] == 'wondible'
end


Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")

  lives_json = []
  server = dir.sub('lifeLog_', '').sub('.onehouronelife.com', '')

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*3)..(to_time + 60*60*24*3)))

  p [dir, lives.length]

  lines = {}
  from = from_time.to_i
  to = to_time.to_i

  lives.select do |life|
    if life.hash == wondible
      life.highlight = true
      p [life.key, life.name, Time.at(life.time)]
      if life.time > from && life.time < to && life.lifetime > 3
        eve = lives.ancestors(life).last

        if life.birth_coords
          p "adding point"
          lives_json << life.birth_coords + [life.name]
        end
        if life.birth_coords
          p "adding point"
          lives_json << life.death_coords + [life.name]
        end

        unless lines[eve.key]
          line = lines[eve.key] = lives.family(eve)
          length = line.length
          #lives.outsiders(line)
          json = []
          line.each do |l|
            if l.birth_coords && l.age > 0.5
              json << l.birth_coords + [l.name]
            end
            l.player_name = known_players[l.hash]
            if l.player_name
              l.highlight = true
            end
          end
          killers = lives.killers(line)
          killers.each do |l|
            l.player_name = known_players[l.hash]
            if l.player_name
              l.highlight = true
            end
          end
          filename = "output/#{Time.at(eve.time).strftime('%Y-%m-%d')}_#{length}_#{eve.name}"
          p [filename, line.length]
          #Graph.graph(line).output(:dot => filename + ".gv")
          Graph.html(filename + ".html", line, killers)
          File.open("#{filename}_points.json", 'wb') do |file|
            file << JSON.generate(json)
          end
        end
      end
    end
  end

  p "#{server} #{lives_json.length}"
  if lives_json.length > 0
    File.open("output/#{server}_points.json", 'wb') do |file|
      file << JSON.generate(lives_json)
    end
  end
end

