class OneLine
  desc 'tree [TERM]', 'output recent family trees of name/hash/id'
  option :eve, :type => :boolean, :desc => 'only eves', :default => false
  def tree(target = known_players.keys.first)
    require 'ohol-family-trees/graph'

    lines = {}
    matching_lives(target) do |life, lives|
      next unless options[:eve] == false || life.chain == 1
      log.warn {"#{Time.at(life.time)} #{life.name} #{life.key if log.info?}"}
      eve = lives.ancestors(life).last

      unless lines[eve.key]
        line = lines[eve.key] = lives.family(eve)
        length = line.length
        #lives.outsiders(line)
        line.each do |l|
          l.player_name = known_players[l.hash]
          if l.hash == target
            l.highlight = true
          end
        end
        killers = lives.killers(line)
        killers.each do |l|
          l.player_name = known_players[l.hash]
        end
        filename = "output/#{Time.at(eve.time).strftime('%Y-%m-%d')}_#{length}_#{eve.name}"
        log.warn "=> #{filename}"
        Graph.html(filename + ".html", line, killers)
      end
    end
  end
end
