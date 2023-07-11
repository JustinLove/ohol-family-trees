class OneLine
  desc 'cursed [TERM]', 'recent accounts which cursed account of character name/hash/id'
  def cursed(term)
    matching_hashes(term).each do |hash|
      puts headline('-', "#{hash} #{known_players[hash]}")
      matching_curses(curselog_time_range) do |curse|
        if curse.to_hash == hash
          log.debug curse.inspect
          puts "#{curse.from_hash[0..7]} #{curse.net} #{known_players[curse.from_hash]} =>"
        end
      end
      puts ""
    end
  end
end
