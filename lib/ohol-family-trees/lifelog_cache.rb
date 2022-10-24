require 'ohol-family-trees/lifelog_file'

module OHOLFamilyTrees
  module LifelogCache
    class Servers
      include Enumerable

      def initialize(cache = "cache/publicLifeLogData/")
        @cache = cache
      end

      attr_reader :cache

      def each(&block)
        iter = Dir.foreach(cache)
          .select {|dir| dir.match("lifeLog_")}
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
        dir.match(/lifeLog_(.*)/)[1]
      end

      def each
        Dir.foreach(File.join(cache, dir)) do |path|
          dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
          next unless dateparts
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

    class Logfile < LifelogFile
      def initialize(path, cache = "cache/publicLifeLogData/")
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
