require 'ruby-graphviz'
require 'color/palette/monocontrast'
require 'color/rgb'

module Graph
  def self.graph(lives)
    g = GraphViz.new(:G, :type => :digraph)
    lives.each do |life|
      uskey = life.key.gsub('.', '')
      us = g.get_node(uskey) || g.add_nodes(uskey)
      us[:label] = [life.name, life.age.to_i, life.cause, life.player_name].compact.join("\n")

      if life.killer
        killerkey = life.killer.gsub('.', '')
        killer = g.get_node(killerkey) || g.add_nodes(killerkey)
        if lives.include?(killerkey)
          g.add_edges(us, killer, :color => 'red', :constraint => 'false')
        else
          g.add_edges(us, killer, :color => 'red')
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
          us[:color] = palette.background[5].html
          us[:style] = 'filled'
          us[:fontcolor] = palette.foreground[-5].html
        else
          us[:color] = palette.background[0].html
          us[:style] = 'filled'
          us[:fontcolor] = palette.foreground[0].html
        end
      end

      if life.highlight
        us[:fontsize] = '48'
      end

      if life.gender == "F"
        us[:shape] = :ellipse
      else
        us[:shape] = :box
      end

      if life.parent == Lifelog::NoParent
        us[:shape] = :egg
      elsif life.parent.nil?
        us[:shape] = :polygon
      else
        parentkey = life.parent.gsub('.', '')
        #g[parent] [:label => lives[life.parent].name]
        parent = g.get_node(parentkey) || g.add_nodes(parentkey)
        g.add_edges(parent, us)
      end
    end

    return g
  end

  def self.html(lives, filename)
    @wrapper ||= File.read(File.dirname(__FILE__) + '/wrapper.html')
    svg = graph(lives).output('svg' => String)
    html = @wrapper.sub('#svg#', svg)
    File.write(filename, html)
  end
end
