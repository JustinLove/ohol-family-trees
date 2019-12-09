require 'ohol-family-trees/tiled_placement_log'
require 'ohol-family-trees/key_plain'
require 'fileutils'
require 'json'
require 'progress_bar'
require 'set'

module OHOLFamilyTrees
  class OutputFinalPlacements
    def arc_path
      "#{output_path}/arcs.json"
    end

    def span_path
      "#{output_path}/spans.json"
    end

    def processed_path
      "#{output_path}/processed.json"
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

    def arcs
      return @arcs if @arcs
      @arcs = {}
      filesystem.read(arc_path) do |f|
        list = JSON.parse(f.read)
        list.each do |arc|
          @arcs[arc['start'].to_s] = arc
        end
      end
      #p @arcs
      @arcs
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
      filesystem.write(arc_path) do |f|
        f << JSON.pretty_generate(arcs.values.sort_by {|arc| arc['start']})
      end
      filesystem.write(span_path) do |f|
        f << JSON.pretty_generate(spans.values.sort_by {|span| span['start']})
      end
      filesystem.write(processed_path) do |f|
        f << JSON.pretty_generate(processed)
      end
    end

    def base_time(logfile, basefile, zoom)
      if basefile
        candidates = spans.values
          .select {|span| basefile.timestamp <= span['start'] && span['end'] <= logfile.timestamp }
          .sort_by {|span| span['end']}
        base_span = candidates.last
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
        loader = KeyPlain.new(filesystem, output_path, zoom)
        return TileSet.new(tile_list, loader)
      end
    end

    def process(logfile, basefile = nil)
      #return if processed[logfile.path] && logfile.cache_valid_at?(processed[logfile.path]['time'])
      processed[logfile.path] = {
        'time' => Time.now.to_i,
        'paths' => []
      }

      p logfile.path

      ZoomLevels.each do |zoom|
        tile_width = 2**(32 - zoom)

        time = base_time(logfile, basefile, zoom)

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :object_over => objects.object_over,
            :base_time => time,
            :base_tiles => base_tileset(time, zoom),
          }) do |span, arc, tileset|

          arcs[arc.s_start.to_s] = {
            'start' => arc.s_start,
            'end' => arc.s_end,
            'seed' => arc.seed,
          }
          #p arcs

          spans[span.s_start.to_s] = {
            'start' => span.s_start,
            'end' => span.s_end,
            'base' => span.s_base,
            'seed' => span.seed,
          }
          #p spans

          write_tiles(tileset.updated_tiles, span.s_end, zoom)
          write_index(tileset.tile_index(span.s_end), span.s_end, zoom)

          processed[logfile.path]['paths'] << span.s_end.to_s
          #p processed
        end
      end

      checkpoint
    end

    def write_tiles(tiles, dir, zoom)
      p "write #{dir}/#{zoom}"
      writer = KeyPlain.new(filesystem, output_path, zoom)
      bar = ProgressBar.new(tiles.length)
      tiles.each_pair do |coords,tile|
        bar.increment!
        next if tile.empty?
        writer.write(tile, dir)
      end
    end

    def read_tiles(dir, zoom, tile_list)
      #p dir, zoom
      reader = KeyPlain.new(filesystem, output_path, zoom)
      bar = ProgressBar.new(tile_list.length)
      tiles = TileSet.new
      tile_list.each do |triple|
        tilex, tiley, timestamp = *triple
        coords = [tilex, tiley]
        bar.increment!
        #p coords
        tiles[coords] = reader.read(coords, timestamp)
      end
      return tiles
    end

    def list_tiles(dir, zoom)
      #p dir, zoom
      prefix = "#{output_path}/#{dir}/#{zoom}"
      p "list #{prefix}"
      paths = filesystem.list(prefix)
      tiles = []
      paths.each do |path|
        next unless path.match('.txt')
        #p path
        parts = path.split(/[\/\.]/)
        coords = [parts[3].to_i,parts[4].to_i]
        #p coords
        tiles << coords
      end
      return tiles
    end

    def write_index(triples, dir, zoom)
      path = "#{output_path}/#{dir}/#{zoom}/index.txt"
      p "write #{path}"
      filesystem.write(path) do |out|
        lasty = nil
        lastt = nil
        triples.sort {|a,b|
            (a[2] <=> b[2])*4 +
              (b[1] <=> a[1])*2 +
              (a[0] <=> b[0])
          }.each do |tilex, tiley, time|
          if time != lastt
            if lastt
              out << "\n"
            end
            lastt = time
            lasty = nil
            out << "t#{time}"
          end
          if tiley != lasty
            lasty = tiley
            out << "\n#{tiley}"
          end
          out << " #{tilex}"
        end
      end
    end

    def read_index(dir, zoom, cutoff)
      path = "#{output_path}/#{dir}/#{zoom}/index.txt"
      p "read #{path}"
      tile_list = []
      timestamp = dir
      filesystem.read(path) do |file|
        file.each_line do |line|
          if line[0] == 't'
            timestamp = line[1..-1].to_i
          end
          next if timestamp < cutoff
          parts = line.split(' ').map(&:to_i)
          tiley = parts.shift
          parts.each do |tilex|
            tile_list << [tilex,tiley,timestamp]
          end
        end
      end
      return tile_list
    end
  end
end

