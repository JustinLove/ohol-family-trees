require 'ohol-family-trees/tiled_placement_log'
require 'fileutils'
require 'json'

module OHOLFamilyTrees
  class OutputMaplog
    def processed_path
      "#{output_dir}/processed.json"
    end

    ZoomLevels = 24..27
    FullDetail = 27

    attr_reader :output_dir
    attr_reader :objects

    def initialize(output_dir, objects)
      @output_dir = output_dir
      @objects = objects
      FileUtils.mkdir_p(output_dir)
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
        cellSize = 2**(zoom - 24)
        if zoom >= FullDetail
          min_size = 0
        else
          min_size = 1.5 * (128/cellSize)
        end

        p zoom

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :min_size => min_size,
            :object_size => objects.object_size,
            :object_over => objects.object_over,
          }).each do |tiled|

          write_tiles(tiled.placements, tiled.arc.s_end, zoom)

          processed[logfile.path]['paths'] << "#{tiled.arc.s_end.to_s}/#{zoom}"
          #p processed
        end
      end

      checkpoint
    end

    def write_tiles(map, dir, zoom)
      p dir
      map.each do |coords,tile|
        tilex, tiley = *coords
        next if tile.empty?
        FileUtils.mkdir_p("#{output_dir}/#{dir}/#{zoom}/#{tilex}")
        File.open("#{output_dir}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt", 'wb') do |out|
          last_x = 0
          last_y = 0
          last_time = 0
          tile.each do |logline|
            out << "#{(logline.ms_time - last_time)/10} #{logline.x - last_x} #{logline.y - last_y} #{logline.object}\n"
            last_time = logline.ms_time
            last_x = logline.x
            last_y = logline.y
          end
        end
      end
    end
  end
end

