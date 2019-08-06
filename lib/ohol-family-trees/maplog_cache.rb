module OHOLFamilyTrees
  module MaplogCache
    class Servers
      include Enumerable

      def initialize(cache = "cache/map/")
        @cache = cache
      end

      attr_reader :cache

      def each(&block)
        iter = Dir.foreach(cache)
          .select {|dir| dir.match("onehouronelife.com")}
          .map {|dir| Logs.new(dir, cache) }
        if block_given?
          iter.each(&block)
        end
      end
    end

    class Logs
      include Enumerable

      def initialize(dir, cache = "cache/map/")
        @dir = dir
        @cache = cache
      end

      attr_reader :dir
      attr_reader :cache

      def server
        dir
      end

      def each
        Dir.foreach(File.join(cache, dir)) do |path|
          next unless path.match('_mapLog.txt')
          cache_path = File.join(dir, path)
          yield Logfile.new(cache_path, cache)
        end
      end
    end

    class Logfile
      def initialize(path, cache = "cache/map/")
        @path = path
        @cache = cache
      end

      attr_reader :path
      attr_reader :cache

      def file_path
        File.join(cache, path)
      end

      def approx_log_time
        return date unless timestamp

        Time.at(timestamp)
      end

      def within(time_range = (Time.at(0)..Time.now))
        time_range.cover?(approx_log_time)
      end

      def date
        File.mtime(file_path)
      end

      def server
        path.match(/(.*onehouronelife.com)\//)[1]
      end

      def timestamp
        path.match(/(\d{10})time_/)[1].to_i
      end

      def seed
        path.match(/_(\d+)seed/)[1].to_i
      end

      def open
        File.open(file_path, "r", :external_encoding => 'ASCII-8BIT')
      end
    end
  end
end