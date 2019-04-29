require 'lifelog'
require 'history'
require 'graph'
require 'date'

wondible = 'e45aa4e489b35b6b0fd9f59f0049c688237a9a86'
from_time = (Date.today - 2).to_time
to_time = (Date.today - 0).to_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*3)..(to_time + 60*60*24*3)))

  p lives.length

  lines = {}
  from = from_time.to_i
  to = to_time.to_i

  lives.select do |life|
    if life.hash == wondible
      life.highlight = true
      p [life.key, life.name, Time.at(life.time)]
      if life.time > from && life.time < to && life.age > 3
        eve = lives.ancestors(life).last
        unless lines[eve.key]
          lines[eve.key] = lives.family(eve)
        end
      end
    end
  end

  lines.each do |key,line|
    eve = line[key]
    filename = "output/#{Time.at(eve.time).strftime('%Y-%m-%d')}_#{line.length}_#{eve.name}.html"
    #Graph.graph(line).output(filename, 'dot')
    Graph.html(line, filename)
  end
end
