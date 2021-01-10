class OneLine
  desc 'find [TERM]', 'find a recent life by character name/hash/id/@list'
  option :t, :type => :string, :desc => 'tag for known players if only one life is found'
  def find(term='@subjects.csv')
    if term.start_with?('@')
      log.debug 'list'
      log.debug term
      log.debug term[1..-1]
      CSV.foreach(term[1..-1]) do |row|
        puts headline('-', row.join(' : '))
        @tag = row[1]
        find(row[0])
      end
      return
    end
    found = []
    matching_lives(term) do |life, lives|
      log.debug life.inspect
      lineage = lives.ancestors(life) if log.info?
      log.info { lineage.take(5).map(&:name).join(', ') }
      log.warn Time.at(life.time)
      log.info { [Time.at(lineage[-1].time), lives.family(life).length] }
      puts "#{life.hash} #{known_players[life.hash]}"
      puts ""
      found << life
    end
    if tag && found.length == 1 && !known_players[found.first.hash]
      hash = found.first.hash
      known_players[hash] = tag
      line = %Q%"#{hash}","#{tag}"\n%
      log.warn "adding #{line}"
      open('known-players.csv', 'a') do |f|
        f << line
      end
    end
  end

  private

  def tag
    @tag ||= options[:t]
  end
end
