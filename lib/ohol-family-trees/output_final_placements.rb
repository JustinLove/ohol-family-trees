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

    def process(logfile, basefile = nil)
      #return if processed[logfile.path] && logfile.cache_valid_at?(processed[logfile.path]['time'])
      processed[logfile.path] = {
        'time' => Time.now.to_i,
        'paths' => []
      }

      p logfile.path

      base_span = nil
      if basefile
        candidates = spans.values
          .select {|span| basefile.timestamp <= span['start'] && span['end'] <= logfile.timestamp }
          .sort_by {|span| span['end']}
        base_span = candidates.last
        #p base_span
      end

      ZoomLevels.each do |zoom|
        tile_width = 2**(32 - zoom)

        base_tiled = nil
        if base_span
          base_tiled = read_tiles(base_span['end'], zoom)
        end

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :object_over => objects.object_over,
            :base => base_tiled,
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

          write_tiles(tiled.objects, tiled.floors, tiled.s_end, zoom)

          processed[logfile.path]['paths'] << tiled.s_end.to_s
          #p processed
        end
      end

      checkpoint
    end

    def write_tiles(objects, floors, dir, zoom)
      p "write #{dir}"
      set = Set.new(objects.keys).merge(floors.keys)
      bar = ProgressBar.new(set.length)
      set.each do |coords|
        bar.increment!
        next if floors[coords].empty? && objects[coords].empty?
        tilex, tiley = *coords
        path = "#{output_path}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt"
        #p path
        filesystem.write(path) do |out|
          floors[coords].each do |key,value|
            out << "#{key} #{value}\n"
          end
          objects[coords].each do |key,value|
            out << "#{key} #{value}\n"
          end
        end
      end
    end

    def read_tiles(dir, zoom)
      p "read #{dir}"
      #p dir, zoom
      prefix = "#{output_path}/#{dir}/#{zoom}"
      #p prefix
      paths = filesystem.list(prefix)
      bar = ProgressBar.new(paths.length)
      tiled = TiledPlacementLog.new(0, 0, 0)
      tiled.s_end = dir
      paths.each do |path|
        bar.increment!
        next unless path.match('.txt')
        #p path
        parts = path.split(/[\/\.]/)
        coords = [parts[3].to_i,parts[4].to_i]
        #p coords
        filesystem.read(path) do |file|
          file.each_line do |line|
            parts = line.split(' ')
            if parts[2].start_with?('f')
              tiled.floors[coords]["#{parts[0]} #{parts[1]}"] = parts[2]
            else
              tiled.objects[coords]["#{parts[0]} #{parts[1]}"] = parts[2]
            end
          end
        end
      end
      return tiled
    end
  end
end

