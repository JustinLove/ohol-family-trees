require 'ohol-family-trees/act_png'
require 'ohol-family-trees/tile_index'
require 'fileutils'
require 'json'
require 'progress_bar'
require 'ohol-family-trees/span'
require 'ohol-family-trees/arc'

module OHOLFamilyTrees
  class OutputActivityMap
    def processed_path
      "#{output_path}/processed_actmap.json"
    end

    ZoomLevels = 2..24
    SampleSize = 1
    TileSize = 256/SampleSize

    attr_reader :output_path
    attr_reader :filesystem

    def initialize(output_path, filesystem)
      @output_path = output_path
      @filesystem = filesystem
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
      filesystem.write(processed_path) do |f|
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

      ZoomLevels.each do |zoom|
        tile_width = 2**(32 - zoom)
        sample_size = tile_width/TileSize

        read(logfile, tile_width, sample_size) do |span, tiles|

          write_tiles(tiles, span.s_end, zoom, span.s_end - span.s_start)
          write_index(tiles, span.s_end, zoom)

          processed[logfile.path]['paths'] << "#{span.s_end.to_s}/#{zoom}"
          #p processed
        end
      end

      checkpoint
    end

    def read(logfile, tile_width, sample_size)
      breakpoints = logfile.breakpoints
      start = nil
      file = logfile.open
      server = logfile.server
      seed = logfile.seed
      span = Span.new(server, 0, seed)
      tiles = {}
      max = 0
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start && span.s_length > 0
            yield [span, tiles]
            if log.s_start < Arc::SplitArcsBefore
              span = Span.new(server, log.s_start, seed)
            else
              span = span.next(log.s_start)
            end
            tiles = {}
            GC.start
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
            yield [span, tiles]
            span = span.next(log.s_time)
            tiles = {}
            GC.start
          end

          span.s_end = log.s_time
          tilex = log.x / tile_width
          tiley = -(log.y / tile_width + 1)
          tile = tiles[[tilex,tiley]] ||= Hash.new {|h,k| h[k] = 0}
          tx = (log.x % tile_width) / sample_size
          ty = (log.y % tile_width) / sample_size
          value = (tile[[tx,ty]] += 1)
          max = [value, max].max
        end
      end
      file.close
      if span.s_length > 1
        yield [span, tiles]
        span = nil
        tiles = nil
        GC.start
      end
      #p ['max', max]
    end

    def write_tiles(tiles, dir, zoom, period)
      p "write #{dir} #{zoom}"
      writer = ActPng.new(filesystem, output_path, zoom, TileSize, period)
      bar = ProgressBar.new(tiles.length)
      tiles.each do |coords,tile|
        bar.increment!
        next if tile.empty?
        writer.write(tile, dir, coords)
      end
    end

    def write_index(tiles, dir, zoom)
      triples = tiles.keys.map {|coords| [coords,dir] }.map(&:flatten)
      writer = TileIndex.new(filesystem, output_path, "am")
      writer.write_index(triples, dir, zoom)
    end
  end
end

