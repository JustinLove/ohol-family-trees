require 'ohol-family-trees/maplog_file'

module OHOLFamilyTrees
  module MaplogCache
    class Servers
      include Enumerable

      def initialize(cache = "cache/publicMapChangeData/")
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

      def initialize(dir, cache = "cache/publicMapChangeData/")
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
          next unless path.match(/_map(Log|Seed).txt/)
          cache_path = File.join(dir, path)
          yield Logfile.new(cache_path, cache)
        end
      end

      def has?(cache_path)
        File.exist?(File.join(cache, cache_path))
      end

      def get(cache_path)
        Logfile.new(cache_path, cache)
      end
    end

    class Logfile < MaplogFile
      def initialize(path, cache = "cache/publicMapChangeData/")
        super path
        @cache = cache
      end

      attr_reader :cache

      def file_path
        File.join(cache, path)
      end

      def date
        File.mtime(file_path)
      end

      def open
        File.open(file_path, "r", :external_encoding => 'ASCII-8BIT')
      end
    end
  end
end
