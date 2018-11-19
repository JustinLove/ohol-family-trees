require 'lifelog'
require 'history'
require 'graph'
require 'date'

(1..15).each do |server|
  lives = History.new

  dir = "cache/lifeLog_server#{server}.onehouronelife.com"
  lives.load_dir(dir)

  p lives.length

  lines = {}

  wondible = 'e45aa4e489b35b6b0fd9f59f0049c688237a9a86'
  from = (Date.today - 1).to_time.to_i
  to = (Date.today - 0).to_time.to_i

  lives.select do |life|
    if life.hash == wondible
      life.highlight = true
      p [life.id, life.name, Time.at(life.time)]
      if life.time > from && life.time < to
        eve = lives.ancestors(life).last
        unless lines[eve.id]
          lines[eve.id] = lives.family(eve)
        end
        #family = lives.family(life)
        #focus.merge!(family)
      end
    end
  end

  lines.each do |id,line|
    eve = line[id]
    Graph.graph(line).output("output/#{eve.name}.gv", 'dot')
  end
end
