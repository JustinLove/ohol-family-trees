require 'graphviz_r'

module Graph
  def self.graph(lives)
    g = GraphvizR.new 'familytree'
    lives.values.each do |life|
      us = g['p'+life.id.to_s]
      if life.parent == Lifelog::NoParent
        us [:shape => :box]
      else
        parent = g['p'+life.parent.to_s]
        parent >> us
      end
    end

    return g
  end
end
