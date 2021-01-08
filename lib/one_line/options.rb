class OneLine
  LogLevels = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN]
  class_option :verbose, :default => 'WARN', :desc => 'DEBUG, INFO, WARN'
  class_option :i, :type => :boolean, :desc => 'verbose=INFO'
  class_option :d, :type => :boolean, :desc => 'verbose=DEBUG'

  class_option :from, :type => :numeric, :desc => 'start days relative to now', :default => -3
  class_option :to, :type => :numeric, :desc => 'stop days relative to now (1 helps with rounding)', :default => 1

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

  def known_players
    return @known_players if @known_players
    @known_players = {}
    CSV.foreach("known-players.csv") do |row|
      @known_players[row[0]] = row[1]
    end
    @known_players
  end
end
