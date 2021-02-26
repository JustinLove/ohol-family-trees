require 'ohol-family-trees/log_value_y_x_t_first'
require 'ohol-family-trees/id_index'
require 'ohol-family-trees/key_value_y_x_first'
require 'ohol-family-trees/cache_control'
require 'ohol-family-trees/content_type'
require 'fileutils'
require 'json'
require 'progress_bar'
require 'ohol-family-trees/span'
require 'ohol-family-trees/arc'

module OHOLFamilyTrees
  class OutputObjectSearchIndex
    def processed_path
      "#{output_path}/processed_logsearch.json"
    end

    attr_reader :output_path
    attr_reader :filesystem
    attr_reader :objects
    attr_reader :notable

    def initialize(output_path, filesystem, objects, notable = [])
      @output_path = output_path
      @filesystem = filesystem
      @objects = objects
      @notable = notable
    end

    def processed
      return @processed if @processed
      @processed = {}
      filesystem.read(processed_path) do |f|
        @processed = JSON.parse(f.read)
      end
      @processed
    end

    def checkpoint
      filesystem.write(processed_path, CacheControl::NoCache.merge(ContentType::Json)) do |f|
        f << JSON.pretty_generate(processed)
      end
    end

    def process(logfile, options = {})
      return if processed[logfile.path] && logfile.cache_valid_at?(processed[logfile.path]['time'])
      processed[logfile.path] = {
        'time' => Time.now.to_i,
        'paths' => []
      }

      p logfile.path

      read(logfile) do |span, index, noted|
        total = index.map {|k,v| v.length}.sum
        cutoff = (total*0.005).to_i
        triples = index.map {|id,list| [id,list,list.length<cutoff]}
        #sorted = index.sort_by {|k,v| v.length}
        #sorted.each do |id, v|
          #p [id, v.length, v.length.to_f/total, objects.names[id.to_s]]
        #end
        #p sorted.reverse.take(5)

        write_object_index(triples, span.s_end)
        write_objects(triples, span.s_end)

        write_notable_objects(noted, span.s_end)

        processed[logfile.path]['paths'] << "#{span.s_end.to_s}"
        #p processed
      end

      checkpoint
    end

    def read(logfile)
      breakpoints = logfile.breakpoints
      start = nil
      file = logfile.open
      server = logfile.server
      seed = logfile.seed
      span = Span.new(server, 0, seed)
      index = {}
      noted = {}
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start && span.s_length > 0
            yield [span, index, noted]
            if log.s_start < Arc::SplitArcsBefore
              span = Span.new(server, log.s_start, seed)
            else
              span = span.next(log.s_start)
            end
            index = {}
            noted = {}
          end
          start = log
          if span.s_start == 0
            span.s_start = start.s_start
          end
          span.s_end = start.s_start
        elsif log.kind_of?(Maplog::Placement)
          log.ms_start = start.ms_start
          if breakpoints.any? && file.lineno > breakpoints.first
            breakpoints.shift
            yield [span, index, noted]
            span = span.next(log.s_time)
            index = {}
            noted = {}
          end

          span.s_end = log.s_time
          id = log.base_id
          if id != 0
            index[id] ||= []
            index[id] << log

            if notable.member? id
              noted[[log.x, log.y]] = id
            end
          end
        end
      end
      file.close
      if span.s_length > 1
        yield [span, index, noted]
      end
    end

    def write_objects(triples, dir)
      p "write #{dir}"
      writer = LogValueYXTFirst.new(filesystem.with_metadata(CacheControl::OneMonth.merge(ContentType::Text)))
      bar = ProgressBar.new(triples.length)
      triples.each do |id,placements,inc|
        bar.increment!
        next if placements.empty?
        next unless inc
        path = "#{output_path}/#{dir}/ls/#{id}.txt"
        #p path
        writer.write(placements, path)
      end
    end

    def write_object_index(triples, dir)
      writer = IdIndex.new(filesystem.with_metadata(CacheControl::OneMonth.merge(ContentType::Text)), output_path, "ls")
      writer.write_index(triples, dir)
    end

    def write_notable_objects(noted, dir)
      writer = KeyValueYXFirst.new(filesystem.with_metadata(CacheControl::OneWeek.merge(ContentType::Text)), output_path, 0)
      path = "#{output_path}/#{dir}/notable.txt"
      triples = noted
        .map {|key,value| key + [value]}
        .sort {|a,b|
        (notable.index(a[2]) <=> notable.index(b[2]))*4 +
            (a[1] <=> b[1])*2 +
            (a[0] <=> b[0])
        }
      writer.write_sorted_triples(triples, path)
    end
  end
end

