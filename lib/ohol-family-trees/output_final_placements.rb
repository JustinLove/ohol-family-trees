require 'ohol-family-trees/tiled_placement_log'
#require 'ohol-family-trees/key_plain'
#require 'ohol-family-trees/key_value_y_x'
require 'ohol-family-trees/key_value_y_x_first'
require 'fileutils'
require 'json'
require 'progress_bar'
require 'set'

module OHOLFamilyTrees
  class OutputFinalPlacements
    def span_path
      "#{output_path}/spans.json"
    end

    def processed_path
      "#{output_path}/processed_keyplace.json"
    end

    ZoomLevels = 24..24

    attr_reader :output_path
    attr_reader :filesystem
    attr_reader :objects

    def initialize(output_path, filesystem, objects)
      @output_path = output_path
      @filesystem = filesystem
      @objects = objects
    end

    def spans
      return @spans if @spans
      @spans = {}
      filesystem.read(span_path) do |f|
        list = JSON.parse(f.read)
        list.each do |span|
          @spans[span['start'].to_s] = span
        end
      end
      #p @spans
      @spans
    end

    def processed
      return @processed if @processed
      @processed = {}
      filesystem.read(processed_path) do |f|
        @processed = JSON.parse(f.read)
      end
      #p @processed
      @processed
    end

    def checkpoint
      x = JSON.pretty_generate(spans.values.sort_by {|span| span['start']})
      filesystem.write(span_path) do |f|
        f << x
      end
      filesystem.write(processed_path) do |f|
        f << JSON.pretty_generate(processed)
      end
    end

    def base_time(logfile, basefile)
      if basefile
        base_span = processed[basefile.path]['spans']
          .sort_by {|span| span['end']}
          .last
        #p base_span
        if base_span
          return base_span['end']
        end
      end
    end

    def base_tileset(time, zoom)
      if time
        cutoff = time - 14 * 24 * 60 * 60
        tile_list = read_index(time, zoom, cutoff)
        loader = KeyValueYXFirst.new(filesystem, output_path, zoom)
        return TileSet.new(tile_list, loader)
      end
    end

    def process(logfile, options = {})
      base_time = base_time(logfile, options[:basefile])

      if processed[logfile.path] &&
        logfile.cache_valid_at?(processed[logfile.path]['time']) && 
        processed[logfile.path]['root_time'] == ((options[:rootfile] && options[:rootfile].timestamp) || 0) &&
        processed[logfile.path]['base_time'] == (base_time || 0)
        return
      end

      processed[logfile.path] = {
        'time' => Time.now.to_i,
        'root_time' => (options[:rootfile] && options[:rootfile].timestamp) || 0,
        'base_time' => base_time || 0,
        'spans' => [],
      }

      p logfile.path

      ZoomLevels.each do |zoom|
        tile_width = 2**(32 - zoom)

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :object_over => objects.object_over,
            :base_time => base_time,
            :base_tiles => base_tileset(base_time, zoom),
          }) do |span, tileset|

          spans[span.s_start.to_s] = {
            'start' => span.s_start,
            'end' => span.s_end,
            'base' => span.s_base,
          }
          #p spans

          write_tiles(tileset.updated_tiles, span.s_end, zoom)
          write_index(tileset.tile_index, span.s_end, zoom)

          processed[logfile.path]['spans'] << {
            'start' => span.s_start,
            'end' => span.s_end,
            'base' => span.s_base,
          }
          #p processed
        end
      end

      checkpoint
    end

    def timestamp_fixup(logfile)
      if processed[logfile.path]
        unless logfile.cache_valid_at?(processed[logfile.path]['time'])
          processed[logfile.path]['time'] = logfile.date.to_i
          checkpoint
        end
      end
    end

    def write_tiles(tiles, dir, zoom)
      p "write #{dir}/#{zoom}"
      writer = KeyValueYXFirst.new(filesystem, output_path, zoom)
      bar = ProgressBar.new(tiles.length)
      tiles.each_pair do |coords,tile|
        bar.increment!
        next if tile.empty?
        writer.write(tile, dir)
      end
    end

    def write_index(triples, dir, zoom)
      writer = TileIndex.new(filesystem, output_path, "kp")
      writer.write_index(triples, dir, zoom)
    end

    def read_index(dir, zoom, cutoff)
      reader = TileIndex.new(filesystem, output_path, "kp")
      reader.read_index(dir, zoom, cutoff)
    end
  end
end

