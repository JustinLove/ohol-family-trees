class OneLine
  desc 'find [TERM]', 'find a recent life by character name/hash/id'
  option :t, :type => :string, :desc => 'tag for known players if only one life is found'
  option :eve, :type => :boolean, :desc => 'only eves', :default => false
  def find(term, tag = options[:t])
    found = []
    matching_lives(term) do |life, lives|
      next unless !options[:eve] || life.chain == 1
      print_life(life, lives)
      found << life
    end

    tagem(found, tag)
  end

  desc 'subjects [filename]', 'find recent lives by file with term,tag pairs'
  def subjects(file = 'subjects.csv')
    CSV.foreach(file) do |row|
      puts headline('-', row.join(' : '))
      find(row[0], row[1])
    end
  end

  desc 'children [PARENT]', 'find recent lives by parent name/hash/id'
  def children(term)
    matching_lives(term) do |life, lives|
      lives.children(life).each do |child|
        log.warn headline('x', 'pedicide') if child.killer == child.parent
        print_life(child, lives)
      end
    end
  end

  desc 'parent [CHILD]', 'find recent lives by child name/hash/id'
  option :t, :type => :string, :desc => 'tag for known players if only one life is found'
  def parent(term)
    found = {}
    matching_lives(term) do |life, lives|
      if life.parent
        mom = lives[life.parent]
        print_life(mom, lives)
        found[mom.key] = mom
      end
    end

    tagem(found.values, options[:t])
  end

  desc 'killers [VICTIM]', 'find recent lives by victim name/hash/id'
  option :t, :type => :string, :desc => 'tag for known players if only one life is found'
  def killers(term)
    found = {}
    matching_lives(term) do |life, lives|
      if life.killer
        kil = lives[life.killer]
        print_life(kil, lives)
        found[kil.key] = kil
      end
    end

    tagem(found.values, options[:t])
  end

  desc 'victims [KILLER]', 'find recent lives by killer name/hash/id'
  option :t, :type => :string, :desc => 'tag for known players if only one life is found'
  def victims(term)
    found = History.new
    matching_lives(term) do |life, lives|
      vic = lives.victims(life)
      vic.each do |v|
        print_life(v, lives)
      end
      found.merge! vic
    end

    tagem(found.lives.values, options[:t])
  end


  private

  def print_life(life, lives)
    log.debug life.inspect
    lineage = lives.ancestors(life) if log.info?
    log.info { lineage.take(5).map(&:name).join(', ') }
    log.warn Time.at(life.time)
    log.info { [Time.at(lineage[-1].time), lives.family(life).length] }
    puts "#{life.hash} #{known_players[life.hash]}"
    puts ""
  end

  def tagem(found, tag)
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
end
