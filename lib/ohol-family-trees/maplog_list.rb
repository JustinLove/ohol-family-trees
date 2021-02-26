require 'ohol-family-trees/maplog_file'
require 'ohol-family-trees/cache_control'
require 'ohol-family-trees/content_type'
require 'json'

module OHOLFamilyTrees
  module MaplogList
    class Logs
      include Enumerable

      def initialize(filesystem, list_path, archive_path)
        @filesystem = filesystem
        @list_path = list_path
        @archive_path = archive_path
      end

      attr_reader :filesystem
      attr_reader :list_path
      attr_reader :archive_path

      def files
        return @files if @files
        @files = {}
        filesystem.read(list_path) do |f|
          list = JSON.parse(f.read)
          list.each do |file|
            @files[file['path']] = Logfile.new(file['path'], Time.at(file['date']), file['seed'], filesystem, archive_path)
          end
        end
        @files
      end

      def checkpoint
        filesystem.write(list_path, CacheControl::NoCache.merge(ContentType::Json)) do |f|
          f << JSON.pretty_generate(to_a.map(&:to_h))
        end
      end

      def each(&block)
        files.values.sort_by(&:path).each(&block)
      end

      def has?(cache_path)
        files.include?(cache_path)
      end

      def get(cache_path)
        files[cache_path]
      end

      def to_a
        files.values.sort_by(&:path)
      end

      def update_from(source)
        source.each do |sourcefile|
          if logfile = files[sourcefile.path]
            # 1 second, to allow for differing sub-second precision
            if sourcefile.date > logfile.date + 1
              files[sourcefile.path] = Logfile.from_source(sourcefile, filesystem, archive_path)
              yield sourcefile if block_given?
            end
          else
            files[sourcefile.path] = Logfile.from_source(sourcefile, filesystem, archive_path)
            yield sourcefile if block_given?
          end
        end
      end
    end

    class Logfile < MaplogFile
      def initialize(path, date, seed, filesystem, archive_path)
        super path
        @date = date
        @seed = seed
        @filesystem = filesystem
        @archive_path = archive_path
      end

      def self.from_source(sourcefile, filesystem, archive_path)
        new(sourcefile.path, sourcefile.date, sourcefile.seed, filesystem, archive_path)
      end

      attr_reader :date
      attr_reader :seed
      attr_reader :filesystem
      attr_reader :archive_path

      def open
        filesystem.open(archive_path + path)
      end

      def to_h
        {
          'path' => path,
          'date' => date.to_i,
          'seed' => seed,
        }
      end
    end
  end
end
