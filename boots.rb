require 'lifelog'
require 'history'
require 'graph'
require 'date'

lives = History.new

# boots family
dir = "cache/lifeLog_server7.onehouronelife.com"
lives.load_dir(dir)
#target = 6897
#focus = lives.family(lives[target])


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

p focus.length

filename = "output/boots.html"
#Graph.graph(focus).output(filename, 'dot')
Graph.html(focus, filename)
