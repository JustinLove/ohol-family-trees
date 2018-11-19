require 'lifelog'
require 'history'
require 'graph'
require 'date'

(1..15).each do |server|
  lives = History.new

  dir = "cache/lifeLog_server#{server}.onehouronelife.com"
  lives.load_dir(dir)

  p lives.length

  focus = History.new

  wondible = 'e45aa4e489b35b6b0fd9f59f0049c688237a9a86'
  from = (Date.today - 1).to_time.to_i
  to = (Date.today - 0).to_time.to_i

  lives.select do |life|
    if life.hash == wondible
      life.highlight = true
      p [life.id, life.name, Time.at(life.time)]
      if life.time > from && life.time < to
        family = lives.family(life)
        focus.merge!(family)
      end
    end
  end

  p focus.length

  Graph.graph(focus).output("output/wondible#{server}.gv", 'dot')
end
