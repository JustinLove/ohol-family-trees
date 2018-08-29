require 'lifelog'
require 'history'
require 'graph'
require 'date'

lives = History.new

dir = "cache/lifeLog_server1.onehouronelife.com"
#dir = "cache/lifeLog_server7.onehouronelife.com"
lives.load_dir(dir)
#lives.load_log(dir+"/2018_08August_19_Sunday.txt")
#lives.load_names(dir+"/2018_08August_19_Sunday_names.txt")

p lives.length

focus = History.new

# larger family
#target = 1110120
#target = 1114108
#focus = lives.family(lives[target])

# small family
#target = 1109187
#focus = lives.family(lives[target])

# small named family
#target = 1110334
#focus = lives.family(lives[target])

#focus = lives

=begin

lives.select do |life|
  if life.name == 'LILLY'
    p life
    family = lives.family(life)
    p family.length
    focus.merge!(family)
  end
end

from = (Date.today << 4).to_time.to_i
to = (Date.today << 2).to_time.to_i


lives.select do |life|
  if life.time > from && life.time < to && life.name == 'LILLY'
    lineage = lives.ancestors(life)
    if lineage[1] && lineage[1].name == 'ANA' && lineage[-1].name == 'EVE WEST'
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

=end

p focus.length

Graph.graph(focus).output('family_tree.gv', 'dot')
