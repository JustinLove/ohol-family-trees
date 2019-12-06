require 'ohol-family-trees/tiled_placement_log'
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

    def base_tiled(logfile, basefile, zoom)
      if basefile
        candidates = spans.values
          .select {|span| basefile.timestamp <= span['start'] && span['end'] <= logfile.timestamp }
          .sort_by {|span| span['end']}
        base_span = candidates.last
        #p base_span
        if base_span
          tile_list = read_index(base_span['end'], zoom)
          return read_tiles(base_span['end'], zoom, tile_list)
        end
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

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :object_over => objects.object_over,
            :base => base_tiled(logfile, basefile, zoom),
          }) do |tiled|

          arcs[tiled.arc.s_start.to_s] = {
            'start' => tiled.arc.s_start,
            'end' => tiled.arc.s_end,
            'seed' => tiled.arc.seed,
          }
          #p arcs

          spans[tiled.s_start.to_s] = {
            'start' => tiled.s_start,
            'end' => tiled.s_end,
            'base' => tiled.s_base,
            'seed' => tiled.seed,
          }
          #p spans

          write_tiles(tiled.updated_tiles, tiled.s_end, zoom)
          write_index(tiled.tile_index, tiled.s_end, zoom)

          processed[logfile.path]['paths'] << tiled.s_end.to_s
          #p processed
        end
      end

      checkpoint
    end

    def write_tiles(tiles, dir, zoom)
      p "write #{dir}/#{zoom}"
      bar = ProgressBar.new(tiles.length)
      tiles.each_pair do |coords,tile|
        bar.increment!
        next if tile.floors.empty? && tile.objects.empty?
        tilex, tiley = *coords
        path = "#{output_path}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt"
        #p path
        filesystem.write(path) do |out|
          tile.floors.each do |key,value|
            out << "#{key} #{value}\n"
          end
          tile.objects.each do |key,value|
            out << "#{key} #{value}\n"
          end
        end
      end
    end

    def read_tiles(dir, zoom, tile_list)
      #p dir, zoom
      bar = ProgressBar.new(tile_list.length)
      tiled = TiledPlacementLog.new(0, 0, 0)
      tiled.s_end = dir
      tile_list.each do |triple|
        tilex, tiley, timestamp = *triple
        coords = [tilex,tiley]
        bar.increment!
        #p coords
        path = "#{output_path}/#{timestamp}/#{zoom}/#{tilex}/#{tiley}.txt"
        tile = tiled.tiles[coords] = TiledPlacementLog::Tile.new(coords, timestamp)
        #p path
        filesystem.read(path) do |file|
          file.each_line do |line|
            parts = line.split(' ')
            if parts[2].start_with?('f')
              tile.set_floor(parts[0], parts[1], parts[2])
            else
              tile.set_object(parts[0], parts[1], parts[2])
            end
          end
        end
      end
      return tiled
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

    def read_index(dir, zoom)
      path = "#{output_path}/#{dir}/#{zoom}/index.txt"
      p "read #{path}"
      tile_list = []
      timestamp = dir
      filesystem.read(path) do |file|
        file.each_line do |line|
          if line[0] == 't'
            timestamp = line[1..-1].to_i
          end
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

