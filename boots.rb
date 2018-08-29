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

from = (Date.today << 4).to_time.to_i
to = (Date.today << 2).to_time.to_i

lives.select do |life|
  if life.time > from && life.time < to && life.name == 'LITA BOOTS'
    lineage = lives.ancestors(life)
    if lineage[1] && lineage[1].name == 'KING BOOTS' && lineage[-1].name == 'EVE BOOTS'
      p life
      p Time.at(life.time)
      p Time.at(lineage[-1].time)
      p life.id
      p lineage.map(&:name).join(', ')
      family = lives.family(life)
      #p family.length
      focus.merge!(family)
    end
  end
end

p focus.length

Graph.graph(focus).output('boots.gv', 'dot')
