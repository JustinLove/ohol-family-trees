class MaplogFile
  def initialize(path)
    @path = path
  end

  attr_reader :path

  def approx_log_time
    return date unless timestamp

    Time.at(timestamp)
  end

  def within(time_range = (Time.at(0)..Time.now))
    time_range.cover?(approx_log_time)
  end

  def server
    path.match(/(.*onehouronelife.com)\//)[1]
  end

  def timestamp
    path.match(/(\d{10})time_/)[1].to_i
  end

  def cache_valid_at?(at_time)
    date.to_i <= at_time && (at_time < 1571853427 || 1572325200 < at_time)
  end

  def seed
    if timestamp == 1571995987
      return nil
    elsif timestamp == 1572240860
      return 30691433003
    elsif timestamp == 1572297324
      return nil
    end
    match = path.match(/_(\d+)seed/)
    match && match[1].to_i
  end

  def merges_with?(file)
    seed && file.seed && seed == file.seed
  end
end
