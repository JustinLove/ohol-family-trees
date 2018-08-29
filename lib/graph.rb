require 'graphviz_r'
require 'color/palette/monocontrast'
require 'color/rgb'

module Graph
  def self.graph(lives)
    g = GraphvizR.new 'familytree'
    lives.each do |life|
      us = life.id.to_s
      g[us] [:label => [life.name, life.age.to_i, life.cause].join("\n")]

      if life.cause.match('killer')
        killer = life.cause.sub('killer_', '')
        if lives.include?(killer.to_i)
          (g[us] >> g[killer]) [:color => 'red', :constraint => 'false']
        else
          (g[us] >> g[killer]) [:color => 'red']
        end
      end

      if life.hash
        hash = life.hash.gsub(/[^0-9a-f]/,'')
        sback = "#" + hash[0..5]
        sfore = "#" + hash[6..11]
        cback = Color::RGB.from_html(sback)
        cfore = Color::RGB.from_html(sfore)
        palette = Color::Palette::MonoContrast.new(cback, cfore)
        if life.age < 3
          g[us] [:color => palette.background[5].html, :style => 'filled', :fontcolor => palette.foreground[-5].html]
        else
          g[us] [:color => palette.background[0].html, :style => 'filled', :fontcolor => palette.foreground[0].html]
        end
      end

      if life.highlight
        g[us] [:fontsize => '48']
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
