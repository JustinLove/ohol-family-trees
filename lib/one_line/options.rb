class OneLine
  LogLevels = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN]
  class_option :verbose, :default => 'WARN', :desc => 'DEBUG, INFO, WARN'
  class_option :i, :type => :boolean, :desc => 'verbose=INFO'
  class_option :d, :type => :boolean, :desc => 'verbose=DEBUG'

  class_option :from, :type => :numeric, :desc => 'start days relative to now', :default => 3
  class_option :to, :type => :numeric, :desc => 'stop days relative to now (-1 helps with rounding)', :default => -1

  class_option :servers, :type => :string, :desc => 'servers to search all/bsN/sN', :default => 'bs2,s1'
  class_option :a, :type => :boolean, :desc => 'all servers', :default => false

  class_option :cache, :type => :string, :desc => 'local data file cache', :default => 'cache'

  private
  def verbose
    d = options[:d] && 'DEBUG'
    i = options[:i] && 'INFO'
    v = options[:verbose].to_s.upcase
    ([d, i, v, "WARN"] & LogLevels).compact.first
  end

  def from_time
    @from_time ||= (Date.today - options[:from]).to_time
  end

  def to_time
    @to_time ||= (Date.today - options[:to]).to_time
  end

  def life_time_range
    (from_time - 60*60*24*3)..(to_time + 60*60*24*3)
  end

  def map_time_range
    (from_time..to_time)
  end

  def from
    @from ||= from_time.to_i
  end

  def to
    @to ||= to_time.to_i
  end

  def servers
    return @servers if @servers
    @servers = Set.new
    if options[:a]
      (1..2).each { |n| @servers << "bigserver#{n}.onehouronelife.com" }
      (1..15).each { |n| @servers << "server#{n}.onehouronelife.com" }
    else
      options[:servers].split(',').each do |s|
        @servers << s
          .gsub(/bs(\d)/, 'bigserver\1.onehouronelife.com')
          .gsub(/s(\d)/, 'server\1.onehouronelife.com')
      end
    end
    log.debug { "Searching" }
    log.debug { @servers.to_a.join("\n") }
    @servers
  end

  def cache
    options[:cache]
  end

  def known_players
    return @known_players if @known_players
    @known_players = {}
    CSV.foreach("known-players.csv") do |row|
      @known_players[row[0]] = row[1]
    end
    @known_players
  end

  def headline(h = '-', s = nil)
    if s
      l = 76 - s.length
      [h*(l/2), s, h*((l+1)/2)].join(' ')
    else
      h*78
    end
  end

  def print_actors(actors)
    found = []
    matching_lives(actors) do |life, lives|
      log.debug life.inspect
      found << life
    end
    found.group_by {|life| life.hash}.each do |hash, chars|
      puts "## #{hash[0,7]} #{known_players[hash]} ".ljust(76, '#')
      chars.each do |life|
        puts "#{life.playerid} #{life.name}"
      end
      puts ""
    end
  end

  def matching_lives(term)
    log.info { "#{from_time} to #{to_time}" }
    hash = name = id = actors = nil
    if term.kind_of?(Set)
      actors = term
    elsif term.length == 40
      hash = term
    elsif term.to_i != 0
      id = term.to_i
    else
      name = term.upcase
    end
    LifelogCache::Servers.new("#{cache}/publicLifeLogData/").each do |logs|
      next unless servers.include? logs.server

      lives = History.new
      lives.load_server(logs, life_time_range)

      filtered = lives

      if actors
        filtered = filtered.select { |life| actors.member?(life.playerid) }
      end
      if hash
        filtered = filtered.select { |life| life.hash == hash }
      end
      if id
        filtered = filtered.select { |life| life.playerid == id }
      end
      if name
        filtered = filtered.select { |life| life.name == name }
      end

      filtered
        .each { |life| life.highlight == true }
        .select { |life| life.time > from && life.time < to }
        .each { |life| yield life, lives }
    end
  end

  def matching_placements
    MaplogCache::Servers.new.each do |logs|
      log.debug logs

      logs.each do |logfile|
        next unless map_time_range.member?(logfile.approx_log_time)
        log.info logfile.path
        file = logfile.open
        start = 0
        while line = file.gets
          log = Maplog.create(line)
          if log.kind_of?(Maplog::ArcStart)
            start = log.ms_start
          elsif log.kind_of?(Maplog::Placement)
            log.ms_start = start
            yield log
          end
        end
      end
    end
  end
end
