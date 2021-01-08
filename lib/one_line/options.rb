class OneLine
  LogLevels = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN]
  class_option :verbose, :default => 'WARN', :desc => 'DEBUG, INFO, WARN'
  class_option :i, :type => :boolean, :desc => 'verbose=INFO'
  class_option :d, :type => :boolean, :desc => 'verbose=DEBUG'

  class_option :from, :type => :numeric, :desc => 'start days relative to now', :default => -3
  class_option :to, :type => :numeric, :desc => 'stop days relative to now (1 helps with rounding)', :default => 1

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
    @from_time ||= (Date.today + options[:from]).to_time
  end

  def to_time
    @to_time ||= (Date.today + options[:to]).to_time
  end

  def time_range
    (from_time - 60*60*24*3)..(to_time + 60*60*24*3)
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

  def matching_lives(term)
    log.info { "#{from_time} to #{to_time}" }
    hash = name = id = nil
    if (term.length == 40)
      hash = term
    elsif (term.to_i != 0)
      id = term.to_i
    else
      name = term.upcase
    end
    LifelogCache::Servers.new("#{cache}/publicLifeLogData/").each do |logs|
      next unless servers.include? logs.server

      lives = History.new
      lives.load_server(logs, time_range)

      filtered = lives

      if hash
        filtered = filtered.select { |life| life.hash == hash }
      end
      if id
        filtered = filtered.select { |life| life.id == id }
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
end
