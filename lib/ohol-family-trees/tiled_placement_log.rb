require 'ohol-family-trees/span'
require 'ohol-family-trees/tile_set'
require 'ohol-family-trees/arc'
require 'json'

module OHOLFamilyTrees
  class TiledPlacementLog
    def self.read(logfile, tile_width, options = {})
      excluded = 0
      floor_removal = options[:floor_removal] || {}
      min_size = options[:min_size] || 0
      object_size = options[:object_size]
      object_over = options[:object_over] || Hash.new {|h,k| h[k] = ObjectOver.new(2, 2, 2, 4)}
      breakpoints = logfile.breakpoints
      start = nil
      file = logfile.open
      previous = nil
      server = logfile.server
      seed = logfile.seed
      span = Span.new(server, 0, seed)
      tiles = TileSet.new
      if options[:base_tiles]
        tiles = tiles.copy_key(options[:base_tiles])
      end
      if options[:base_time]
        p "resume from #{options[:base_time]}"
        span.s_base = options[:base_time]
      end
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start && span.s_length > 0
            tiles.finalize!(span.s_end)
            yield [span, tiles]
            if log.s_start < Arc::SplitArcsBefore
              span = Span.new(server, log.s_start, seed)
            else
              span = span.next(log.s_start)
            end
            tiles = TileSet.new
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
            tiles.finalize!(span.s_end)
            yield [span, tiles]
            span = span.next(log.s_time)
            tiles = TileSet.new.copy_key(tiles)
          end

          span.s_end = log.s_time
          tilex = log.x / tile_width
          #(-tileY - 1) * tile_width = log.y
          #-tileY - 1 = log.y / tile_width
          #-tileY = log.y / tile_width + 1
          tiley = -(log.y / tile_width + 1)
          tile = tiles[[tilex,tiley]]
          object = log.object
          if log.floor?
            occupant = tile.floor(log.x, log.y)
            tile.add_placement(log)
            tile.set_floor(log.x, log.y, object)
          else
            occupant = tile.object(log.x, log.y)
            removes = floor_removal[object]
            if removes
              if tile.floor(log.x, log.y) == removes &&
                 previous.object == "0" &&
                 previous.x == log.x &&
                 previous.y == log.y &&
                 previous.ms_offset == log.ms_offset
                tile.remove_floor(log.x, log.y)
                previous.object = "f0"
              end
            end

            if object_size
              size = object_size[log.id]
              if !size
                #skip
              elsif size <= min_size
                #p log.id
                excluded += 1
                if occupant && occupant == "0"
                  previous = log
                  next
                else
                  log.object = "0"
                  object = "0"
                end
              end
            end

            if previous &&
               previous.actor == -1 &&
               previous.object == "0" &&
               previous.x == log.x &&
               previous.y == log.y &&
               previous.ms_offset == log.ms_offset
              previous.skip!
            end

            tile.add_placement(log)
            tile.set_object(log.x, log.y, object)
          end
          tx = log.x % tile_width
          ty = log.y % tile_width
          newover = object_over[log.id]&.over(tx, ty, tile_width) || [0, 0]
          oldover = (occupant && object_over[Maplog::Placement.id(occupant)]&.over(tx, ty, tile_width)) || [0, 0]

          overx = 0
          if newover[0] != 0
            overx = newover[0]
          elsif oldover[0] != 0
            overx = oldover[0]
          end
          overy = 0
          if newover[1] != 0
            overy = newover[1]
          elsif oldover[1] != 0
            overy = oldover[1]
          end

          overs = []
          if overx != 0
            overs << [tilex+overx,tiley]
          end
          if overy != 0
            overs << [tilex,tiley+overy]
          end
          if overx != 0 && overy != 0
            overs << [tilex+overx,tiley+overy]
          end
          overs.each do |coord|
            tile = tiles[coord]
            tile.add_placement(log)
            if log.floor?
              # overkill, but I don't want separate bounds for floors, bearskin can hang over
              tile.set_floor(log.x, log.y, object)
            else
              tile.set_object(log.x, log.y, object)
            end
          end
          previous = log
        end
      end
      file.close
      if span.s_length > 1
        tiles.finalize!(span.s_end)
        yield [span, tiles]
      end
      p "excluded #{excluded} objects"
    end

    ObjectOver = Struct.new(:left, :bottom, :right, :top) do
      def over(tx, ty, tile_width)
        overx = 0
        overy = 0
        if tx < left
          overx = -1
        elsif tx >= (tile_width - right)
          overx = 1
        end
        if ty < bottom
          overy = 1
        elsif ty >= (tile_width - top)
          overy = -1
        end
        return [overx, overy]
      end
    end
  end
end
