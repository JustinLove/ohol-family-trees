require 'ohol-family-trees/arc'
require 'ohol-family-trees/span'
require 'ohol-family-trees/tile_set'
require 'json'

module OHOLFamilyTrees
  class TiledPlacementLog
    MaxLog = 24*60*60

    def self.breakpoints(logfile)
      Arc.load_log(logfile).flat_map do |arc|
        length = arc.s_end - arc.s_start
        chunks = (length.to_f / MaxLog).ceil
        chunk = length / chunks
        (1...chunks).map {|i| arc.s_start + chunk*i }
      end
    end

    def self.read(logfile, tile_width, options = {})
      excluded = 0
      floor_removal = options[:floor_removal] || {}
      min_size = options[:min_size] || 0
      object_size = options[:object_size]
      object_over = options[:object_over] || Hash.new {|h,k| h[k] = ObjectOver.new(2, 2, 2, 4)}
      breakpoints = breakpoints(logfile)
      start = nil
      file = logfile.open
      previous = nil
      server = logfile.server
      seed = logfile.seed
      span = Span.new(server, 0, seed)
      arc = Arc.new(server, 0, 0, seed)
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
          if start && log.s_start < Arc::SplitArcsBefore
            yield [span, arc, tiles]
            span = Span.new(server, log.s_start, seed)
            arc = Arc.new(server, log.s_start, log.s_start, seed)
          end
          start = log
          if arc.s_start == 0
            arc.s_start = start.s_start
          end
          if span.s_start == 0
            span.s_start = start.s_start
          end
          arc.s_end = start.s_start
          span.s_end = start.s_start
        elsif log.kind_of?(Maplog::Placement)
          log.ms_start = start.ms_start
          if breakpoints.any? && log.s_time > breakpoints.first
            breakpoints.shift
            yield [span, arc, tiles]
            span = span.next(log.s_time)
            tiles = TileSet.new.copy_key(tiles)
          end

          span.s_end = log.s_time
          arc.s_end = log.s_time
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
              if !size || size <= min_size
                if size
                  #p log.id
                  excluded += 1
                end
                if occupant && occupant != "0"
                  log.object = "0"
                  object = "0"
                else
                  previous = log
                  next
                end
              end
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
        end
        previous = log
      end
      file.close
      yield [span, arc, tiles]
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
