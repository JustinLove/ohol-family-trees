class OneLine
  desc 'cursecount [TERM]', 'estimate current curse count by character name/hash/id'
  def cursecount(term)
    matching_hashes(term).each do |hash|
      puts "#{hash} #{known_players[hash]}"
      count = 0
      matching_curses(cursecount_time_range) do |curse|
        if curse.to_hash == hash
          count += curse.net
        end
      end
      puts count
    end
  end
end
