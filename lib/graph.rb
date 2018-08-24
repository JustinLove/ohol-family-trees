require 'graphviz_r'

module Graph
  def self.graph(lives)
    g = GraphvizR.new 'familytree'
    lives.values.each do |life|
      us = g[life.id.to_s]
      us [:label => life.name]
      us = g[life.id.to_s]

      if life.gender == "F"
        us [:shape => :ellipse]
      else
        us [:shape => :box]
      end
      us = g[life.id.to_s]

      if life.parent == Lifelog::NoParent
        us [:shape => :egg]
      elsif life.parent.nil?
        us [:shape => :polygon]
      else
        parent = g[life.parent.to_s]
        parent [:label => lives[life.parent].name]
        parent = g[life.parent.to_s]
        parent >> us
      end
    end

    return g
  end
end
