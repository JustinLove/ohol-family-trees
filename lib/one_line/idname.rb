class OneLine
  desc 'idname [filename]', 'find recent lives by file with id,tag pairs'
  def idname(file = 'subjects.csv')
    tags = {}
    CSV.foreach(file) do |row|
      tags[row[0].to_i] = row[1]
    end
    changes = 0
    matching_lives(Set.new(tags.keys)) do |life, lives|
      puts headline('-', "#{life.playerid} : #{tags[life.playerid]}")
      print_life(life, lives) if log.info? # in find

      hash = life.hash
      tag = tags[life.playerid]
      if known_players[hash]
        unless known_players[hash].downcase.match(tag.downcase)
          known_players[hash] += ",#{tag}"
          log.warn "updating #{hash} #{known_players[hash]}"
          changes += 1
        end
      else
        known_players[hash] = tag
        log.warn "adding #{hash} #{known_players[hash]}"
        changes += 1
      end
      if changes > 0
        FileUtils.cp("known-players.csv", "output/known-players-#{Time.now.to_i}.csv")
        CSV.open("known-players.csv", 'w', :force_quotes => true) do |csv|
          known_players.each do |hash, tag|
            csv << [hash, tag]
          end
        end
      end
    end
  end
end
