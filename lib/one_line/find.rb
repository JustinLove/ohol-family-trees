class OneLine
  desc 'find [TERM]', 'find a recent life by character name/hash/id/@list'
  def find(term='@subjects.csv')
    if term.start_with?('@')
      log.debug 'list'
      log.debug term
      log.debug term[1..-1]
      CSV.foreach(term[1..-1]) do |row|
        puts headline('-', row.join(' : '))
        find(row[0])
      end
      return
    end
    matching_lives(term) do |life, lives|
      log.debug life.inspect
      lineage = lives.ancestors(life) if log.info?
      log.info { lineage.take(5).map(&:name).join(', ') }
      log.warn Time.at(life.time)
      log.info { [Time.at(lineage[-1].time), lives.family(life).length] }
      puts "#{life.hash} #{known_players[life.hash]}"
      puts ""
    end
  end
end
