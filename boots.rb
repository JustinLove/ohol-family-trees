require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/graph'
require 'date'
require 'csv'

include OHOLFamilyTrees

lives = History.new

# boots family
dir = "cache/lifeLog_server7.onehouronelife.com"
lives.load_dir(dir)
#target = 6897
#focus = lives.family(lives[target])

known_players = {}
CSV.foreach("known-players.csv") do |row|
  known_players[row[0]] = row[1]
end

p lives.length

focus = History.new

lives.select do |life|
  if life.name == 'LITA BOOTS'
    p life
    lineage = lives.ancestors(life)
    p lineage[1]
    if lineage[1] && lineage[1].name == 'KING BOOTS' && lineage[-1].name == 'EVE BOOTS'
      p life
      p Time.at(life.time)
      p Time.at(lineage[-1].time)
      p life.key
      p lineage.map(&:name).join(', ')
      family = lives.family(life)
      p family.length
      focus.merge!(family)
    end
  end
end

#lives.outsiders(focus) #tends to hang outputting
p focus.length

focus.each do |l|
  l.player_name = known_players[l.hash]
  if l.player_name
    l.highlight
  end
end

filename = "output/boots"
#Graph.graph(focus).output(:dot => filename + ".gv")
Graph.html(filename + ".html", focus)
