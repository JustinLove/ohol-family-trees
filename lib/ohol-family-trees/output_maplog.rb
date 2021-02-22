require 'ohol-family-trees/tiled_placement_log'
#require 'ohol-family-trees/log_diff'
#require 'ohol-family-trees/log_value_y_x_t'
require 'ohol-family-trees/log_value_y_x_t_first'
require 'ohol-family-trees/cache_control'
require 'fileutils'
require 'json'
require 'progress_bar'

module OHOLFamilyTrees
  class OutputMaplog
    def processed_path
      "#{output_path}/processed_maplog.json"
    end

    ZoomLevels = 24..27
    FullDetail = 27

    attr_reader :output_path
    attr_reader :filesystem
    attr_reader :objects

    def initialize(output_path, filesystem, objects)
      @output_path = output_path
      @filesystem = filesystem
      @objects = objects
    end

    def processed
      return @processed if @processed
      @processed = {}
      filesystem.read(processed_path) do |f|
        @processed = JSON.parse(f.read)
      end
      @processed
      #p @processed
    end

    def checkpoint
      filesystem.write(processed_path, CacheControl::NoCache) do |f|
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
        cellSize = 2**(zoom - 24)
        if zoom >= FullDetail
          min_size = 0
        else
          min_size = 1.5 * (128/cellSize)
        end

        TiledPlacementLog.read(logfile, tile_width, {
            :floor_removal => objects.floor_removal,
            :min_size => min_size,
            :record_placements => true,
            :object_size => objects.object_size,
            :object_over => objects.object_over,
          }) do |span, tileset|

          write_tiles(tileset.tiles, span.s_end, zoom)

          processed[logfile.path]['paths'] << "#{span.s_end.to_s}/#{zoom}"
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
      end
    end

    def write_tiles(tiles, dir, zoom)
      p "write #{dir} #{zoom}"
      writer = LogValueYXTFirst.new(filesystem.with_metadata(CacheControl::OneMonth))
      bar = ProgressBar.new(tiles.length)
      tiles.each do |coords,tile|
        bar.increment!
        next if tile.placements.empty?
        path = "#{output_path}/#{dir}/ml/#{zoom}/#{tile.tilex}/#{tile.tiley}.txt"
        #p path
        writer.write(tile.placements, path)
      end
    end
  end
end

