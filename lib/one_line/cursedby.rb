class OneLine
  desc 'cursedby [TERM]', 'recent curses by account of character name/hash/id'
  def cursedby(term)
    matching_hashes(term).each do |hash|
      puts headline('-', "#{hash} #{known_players[hash]}")
      matching_curses(curselog_time_range) do |curse|
        if curse.from_hash == hash
          puts "=> #{curse.to_hash[0..7]} #{known_players[curse.to_hash]}"
        end
      end
      puts ""
    end
  end
end
