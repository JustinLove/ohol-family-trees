class OneLine
  desc 'find [TERM]', 'find a recent life by character name/hash/id'
  def find(name)
    matching_lives(name.upcase) do |life, lives|
      puts ""
      log.debug life
      lineage = lives.ancestors(life) if log.info?
      log.info { lineage.take(5).map(&:name).join(', ') }
      log.warn Time.at(life.time)
      log.info { [Time.at(lineage[-1].time), lives.family(life).length] }
      puts "#{life.hash} #{known_players[life.hash]}"
    end
  end
end
