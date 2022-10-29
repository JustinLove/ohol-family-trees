module OHOLFamilyTrees
  class MaplogFile
    MaxLog = 2_500_000

    def initialize(path)
      @path = path
    end

    attr_reader :path

    def placements?
      path.match('_mapLog.txt')
    end

    def seed_only?
      path.match('_mapSeed.txt')
    end

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
      at_time ||= 0
      date.to_i <= at_time && (at_time < 1571853427 || 1572325200 < at_time)
    end

    def seed
      if seed_only?
        content_seed
      else
        path_seed
      end
    end

    def content_seed
      return [] unless seed_only?
      file = open
      seeds = file.read.split(' ').map(&:to_i)
      file.close
      return seeds
    end

    def path_seed
      if timestamp == 1571995987
        return []
      elsif timestamp == 1572240860
        return [30691433003]
      elsif timestamp == 1572297324
        return []
      end
      match = path.match(/_(\d+)seed/)
      [match && match[1].to_i].compact
    end

    def merges_with?(file)
      placements? && file.placements? && seed && file.seed && seed == file.seed
    end

    def breakpoints(maxlog = MaxLog)
      return @breakpoints.dup if @breakpoints
      return [] unless placements?
      file = open
      while file.gets
      end
      lines = file.lineno
      file.close

      if lines < 1
        @breakpoints = []
        return []
      end

      chunks = (lines.to_f / maxlog).ceil
      chunk = lines / chunks
      @breakpoints = ((1...chunks).map {|i| chunk*i })
      return @breakpoints.dup
    end
  end
end
