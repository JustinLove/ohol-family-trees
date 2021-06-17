module OHOLFamilyTrees
  module CurselogCache
    class Servers
      include Enumerable

      def initialize(cache = "cache/publicLifeLogData/")
        @cache = cache
      end

      attr_reader :cache

      def each(&block)
        iter = Dir.foreach(cache)
          .select {|dir| dir.match("curseLog_")}
          .map {|dir| Logs.new(dir, cache) }
        if block_given?
          iter.each(&block)
        end
      end
    end

    class Logs
      include Enumerable

      def initialize(dir, cache = "cache/publicLifeLogData/")
        @dir = dir
        @cache = cache
      end

      attr_reader :dir
      attr_reader :cache

      def server
        dir.match(/curseLog_(.*)/)[1]
      end

      def each
        Dir.foreach(File.join(cache, dir)) do |path|
          dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
          next unless dateparts
          cache_path = File.join(dir, path)
          yield Logfile.new(cache_path, cache)
        end
      end
    end

    class Logfile
      def initialize(path, cache = "cache/publicLifeLogData/")
        @path = path
        @cache = cache
      end

      attr_reader :path
      attr_reader :cache

      def file_path
        File.join(cache, path)
      end

      def approx_log_time
        dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
        return date unless dateparts

        Time.gm(dateparts[1], dateparts[2], dateparts[3])
      end

      def within(time_range = (Time.at(0)..Time.now))
        time_range.cover?(approx_log_time)
      end

      def date
        File.mtime(file_path)
      end

      def server
        path.match(/curseLog_(.*)\//)[1]
      end

      def open
        File.open(file_path, "r", :external_encoding => 'ASCII-8BIT')
      end
    end
  end
end
