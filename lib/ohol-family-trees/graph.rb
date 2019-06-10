require 'ruby-graphviz'
require 'color/palette/monocontrast'
require 'color/rgb'
require 'ohol-family-trees/lifelog'

module OHOLFamilyTrees
  module Graph
    def self.graph(lives, others = {})
      g = GraphViz.new(:G, :type => :digraph)
      lives.each do |life|
        next if life.age > 0 && life.age < 0.5
        us = node(g, life)

        if life.killer
          killernodename = life.killer.gsub('.', '')
          killer = g.get_node(killernodename) || g.add_nodes(killernodename)
          if lives.has_key?(life.killer)
            g.add_edges(us, killer, :color => 'red', :constraint => 'false')
            us[:label] = [life.name, life.age.to_i, "Killed by #{lives[life.killer].name}", life.player_name].compact.join("\n")
          elsif others.has_key?(life.killer)
            g.add_edges(us, killer, :color => 'red')
            us[:label] = [life.name, life.age.to_i, "Killed by #{others[life.killer].name}", life.player_name].compact.join("\n")
          else
            g.add_edges(us, killer, :color => 'red')
          end
        end

        if life.parent == Lifelog::NoParent
        elsif life.parent.nil?
        else
          parentkey = life.parent.gsub('.', '')
          #g[parent] [:label => lives[life.parent].name]
          parent = g.get_node(parentkey) || g.add_nodes(parentkey)
          g.add_edges(parent, us, :penwidth => 2)
        end
      end

      others.each do |life|
        node(g, life)
      end

      return g
    end

    def self.node(g, life)
      ournodename = life.key.gsub('.', '')
      us = g.get_node(ournodename) || g.add_nodes(ournodename)
      us[:label] = [life.name, life.age.to_i, life.cause, life.player_name].compact.join("\n")

      if life.hash
        hash = life.hash.gsub(/[^0-9a-f]/,'')
        sback = "#" + hash[0..5]
        sfore = "#" + hash[6..11]
        cback = Color::RGB.from_html(sback)
        cfore = Color::RGB.from_html(sfore)
        palette = Color::Palette::MonoContrast.new(cback, cfore)
        if life.age < 3
          us[:fillcolor] = palette.background[5].html
          us[:color] = palette.foreground[-5].html
          us[:penwidth] = 1
          us[:style] = 'filled,solid'
          us[:fontcolor] = palette.foreground[-5].html
        else
          us[:fillcolor] = palette.background[0].html
          us[:color] = sfore
          us[:penwidth] = 4
          us[:style] = 'filled,solid'
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
      end

      return us
    end

    def self.html(filename, lives, others = {})
      @wrapper ||= File.read(File.dirname(__FILE__) + '/wrapper.html')
      svg = graph(lives, others).output('svg' => String)
      html = @wrapper.sub('#svg#', svg)
      File.write(filename, html)
    end
  end
end
