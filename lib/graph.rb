require 'graphviz_r'

module Graph
  def self.graph(lives)
    g = GraphvizR.new 'familytree'
    lives.values.each do |life|
      us = life.id.to_s
      g[us] [:label => [life.name, life.age.to_i, life.cause].join("\n")]

      if life.cause.match('killer')
        killer = life.cause.sub('killer_', '')
        (g[us] >> g[killer]) [:color => 'red', :constraint => 'false']
      end

      if life.gender == "F"
        g[us] [:shape => :ellipse]
      else
        g[us] [:shape => :box]
      end

      if life.parent == Lifelog::NoParent
        g[us] [:shape => :egg]
      elsif life.parent.nil?
        g[us] [:shape => :polygon]
      else
        parent = life.parent.to_s
        #g[parent] [:label => lives[life.parent].name]
        g[parent] >> g[us]
      end
    end

    return g
  end
end
