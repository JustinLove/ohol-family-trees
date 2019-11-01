module OHOLFamilyTrees
  class CombinedLogfile
    def initialize(logfiles)
      @logfiles = logfiles
    end

    attr_reader :logfiles

    def path
      logfiles.last.path
    end

    def cache
      logfiles.last.cache
    end

    def file_path
      logfiles.last.file_path
    end

    def date
      logfiles.last.date
    end

    def server
      logfiles.last.server
    end

    def cache_valid_at?(at_time)
      logfiles.each do |logfile|
        return false unless logfile.cache_valid_at?(at_time)
      end
      return true
    end

    def seed
      logfiles.last.seed
    end

    def open
      CombinedFile.new(logfiles)
    end
  end

  class CombinedFile
    def initialize(logfiles)
      @queue = logfiles.dup
      @current = queue.shift.open
    end

    attr_reader :queue
    attr_reader :current

    def gets
      value = current.gets
      if current.eof? && queue.any?
        @current.close
        @current = queue.shift.open
      end
      value
    end

    def eof?
      current.eof?
    end

    def close
      current && current.close
    end
  end
end
