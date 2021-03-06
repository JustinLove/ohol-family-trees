require 'ohol-family-trees/tiled_placement_log'
#require 'ohol-family-trees/key_plain'
#require 'ohol-family-trees/key_value_y_x'
require 'ohol-family-trees/key_value_y_x_first'
require 'ohol-family-trees/id_index'
require 'ohol-family-trees/cache_control'
require 'ohol-family-trees/content_type'
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
      filesystem.write(span_path, CacheControl::NoCache.merge(ContentType::Json)) do |f|
        f << x
      end
      filesystem.write(processed_path, CacheControl::NoCache.merge(ContentType::Json)) do |f|
        f << JSON.pretty_generate(processed)
      end
    end

    def base_time(logfile, basefile)
      if basefile && processed[basefile.path]
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

      time_processed = Time.now.to_i
      time_tiles = time_processed
      time_objects = time_processed
      should_write_tiles = true
      should_write_objects = true

      record = processed[logfile.path]
      if record &&
        record['root_time'] == ((options[:rootfile] && options[:rootfile].timestamp) || 0) &&
        record['base_time'] == (base_time || 0)
        if logfile.cache_valid_at?(record['time'] || 0)
          should_write_tiles = false
          time_tiles = record['time']
        end
        if logfile.cache_valid_at?(record['time_objects'] || 0)
          should_write_objects = false
          time_objects = record['time_objects']
        end
      end

      return unless should_write_tiles || should_write_objects

      processed[logfile.path] = {
        'time' => time_tiles,
        'time_objects' => time_objects,
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

          if span.s_length > 1
            spans[span.s_start.to_s] = {
              'start' => span.s_start,
              'end' => span.s_end,
              'base' => span.s_base,
            }
            #p spans

            if should_write_tiles
              write_tiles(tileset.updated_tiles, span.s_end, zoom)
              write_index(tileset.tile_index, span.s_end, zoom)
            end

            if should_write_objects
              index = tileset.object_index(tile_width)

              total = index.map {|k,v| v.length}.sum
              cutoff = (total*0.01).to_i
              triples = index.map {|id,list| [id,list,list.length<cutoff]}
              #sorted = index.sort_by {|k,v| v.length}
              #sorted.each do |id, v|
              #  p [id, v.length, v.length.to_f/total, objects.names[id.to_s]]
              #end
              #p sorted.reverse.take(5)

              write_object_index(triples, span.s_end)
              write_objects(triples, span.s_end)
            end

            processed[logfile.path]['spans'] << {
              'start' => span.s_start,
              'end' => span.s_end,
              'base' => span.s_base,
            }
          elsif processed[logfile.path]['spans'].length < 1
            processed[logfile.path]['spans'] << {
              'start' => span.s_base,
              'end' => span.s_base,
              'base' => span.s_base,
            }
          end

          #p processed
        end
      end

      checkpoint
    end

    def timestamp_fixup(logfile)
      if processed[logfile.path]
        unless logfile.cache_valid_at?(processed[logfile.path]['time'] || 0)
          processed[logfile.path]['time'] = logfile.date.to_i
          checkpoint
        end
        unless logfile.cache_valid_at?(processed[logfile.path]['time_objects'] || 0)
          processed[logfile.path]['time_objects'] = logfile.date.to_i
          checkpoint
        end
      end
    end

    def write_tiles(tiles, dir, zoom)
      p "write tiles #{dir}/#{zoom}"
      writer = KeyValueYXFirst.new(filesystem.with_metadata(CacheControl::OneWeek.merge(ContentType::Text)), output_path, zoom)
      bar = ProgressBar.new(tiles.length)
      tiles.each_pair do |coords,tile|
        bar.increment!
        next if tile.empty?
        writer.write(tile, dir)
      end
    end

    def write_index(triples, dir, zoom)
      writer = TileIndex.new(filesystem.with_metadata(CacheControl::OneWeek.merge(ContentType::Text)), output_path, "kp")
      writer.write_index(triples, dir, zoom)
    end

    def read_index(dir, zoom, cutoff)
      reader = TileIndex.new(filesystem, output_path, "kp")
      reader.read_index(dir, zoom, cutoff)
    end

    def write_objects(object_triples, dir)
      p "write objects #{dir}"
      writer = KeyValueYXFirst.new(filesystem.with_metadata(CacheControl::OneWeek.merge(ContentType::Text)), output_path, 0)
      bar = ProgressBar.new(object_triples.length)
      object_triples.each do |id,list_coords,inc|
        bar.increment!
        next if list_coords.empty?
        next unless inc
        path = "#{output_path}/#{dir}/ks/#{id}.txt"
        #p path
        triples = list_coords.map {|coords| coords + [id]}
        writer.write_triples(triples, path)
      end
    end

    def write_object_index(triples, dir)
      writer = IdIndex.new(filesystem.with_metadata(CacheControl::OneWeek.merge(ContentType::Text)), output_path, "ks")
      writer.write_index(triples, dir)
    end
  end
end

