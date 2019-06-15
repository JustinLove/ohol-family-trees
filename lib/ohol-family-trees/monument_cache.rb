module OHOLFamilyTrees
  module MonumentCache
    CachePath = "cache/monuments/"

    def self.monument_count(cache = CachePath)
      contents = File.read(File.join(cache, "monumentStats.php"))
      if contents && match = contents.match(/(\d+) monuments completed/)
        match[1].to_i
      end
    end

    class Servers
      include Enumerable

      def initialize(cache = CachePath)
        @cache = cache
      end

      attr_reader :cache

      def each(&block)
        iter = Dir.foreach(cache)
          .select {|dir| dir.match("onehouronelife.com.php")}
          .map {|dir| Logfile.new(dir, cache) }
        if block_given?
          iter.each(&block)
        end
      end
    end

    class Logfile
      def initialize(path, cache = CachePath)
        @path = path
        @cache = cache
      end

      attr_reader :path
      attr_reader :cache

      def file_path
        File.join(cache, path)
      end

      def date
        File.mtime(file_path)
      end

      def server
        path.sub('.php', '')
      end

      def read
        File.read(file_path)
      end
    end
  end
end
