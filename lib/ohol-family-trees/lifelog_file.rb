class LifelogFile
  def initialize(path)
    @path = path
  end

  attr_reader :path

  def approx_log_time
    dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
    return date unless dateparts

    Time.gm(dateparts[1], dateparts[2], dateparts[3])
  end

  def within(time_range = (Time.at(0)..Time.now))
    time_range.cover?(approx_log_time)
  end

  def server
    path.match(/lifeLog_(.*)\//)[1]
  end

  def names?
    path.match('_names.txt')
  end

  def cache_valid_at?(at_time)
    at_time ||= 0
    date.to_i <= at_time && (at_time < 1571853427 || 1572325200 < at_time)
  end
end
