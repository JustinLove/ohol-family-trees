require 'ohol-family-trees/tiled_placement_log'
require 'fileutils'
require 'json'
require 'progress_bar'

module OHOLFamilyTrees
  class OutputFinalPlacements
    def arc_path
      "#{output_dir}/#{output_path}/arcs.json"
    end

    def processed_path
      "#{output_dir}/#{output_path}/processed.json"
    end

    ZoomLevels = 24..24

    attr_reader :output_dir
    attr_reader :output_path
    attr_reader :filesystem
    attr_reader :objects

    def initialize(output_dir, output_path, filesystem, objects)
      @output_dir = output_dir
      @output_path = output_path
      @filesystem = filesystem
      @objects = objects
      FileUtils.mkdir_p("#{output_dir}/#{output_path}")
    end

    def arcs
      return @arcs if @arcs
      @arcs = {}
      if File.exist?(arc_path)
        list = JSON.parse(File.read(arc_path))
        list.each do |arc|
          @arcs[arc['start'].to_s] = arc
        end
      end
      @arcs
      #p @arcs
    end

    def processed
      return @processed if @processed
      @processed = {}
      if File.exist?(processed_path)
        @processed = JSON.parse(File.read(processed_path))
      end
      @processed
      #p @processed
    end

    def checkpoint
      File.write(arc_path, JSON.pretty_generate(arcs.values.sort_by {|arc| arc['start']}))
      File.write(processed_path, JSON.pretty_generate(processed))
    end

    def process(logfile)
      return if processed[logfile.path] && logfile.date.to_i <= processed[logfile.path]['time']
      processed[logfile.path] = {
        'time' => Time.now.to_i,
        'paths' => []
      }

      ZoomLevels.each do |zoom|
        tile_width = 2**(32 - zoom)

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :object_over => objects.object_over,
          }).each do |tiled|

          arcs[tiled.arc.s_start.to_s] = {
            'start' => tiled.arc.s_start,
            'end' => tiled.arc.s_end,
            'seed' => tiled.arc.seed,
          }
          #p arcs

          write_tiles(tiled.objects, tiled.floors, tiled.arc.s_end, zoom)

          processed[logfile.path]['paths'] << tiled.arc.s_end.to_s
          #p processed
        end
      end

      checkpoint
    end

    def write_tiles(objects, floors, dir, zoom)
      p dir
      set = (objects.keys | floors.keys)
      bar = ProgressBar.new(set.length)
      set.each do |coords|
        bar.increment!
        next if floors[coords].empty? && objects[coords].empty?
        tilex, tiley = *coords
        path = "#{output_path}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt"
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
  end
end

