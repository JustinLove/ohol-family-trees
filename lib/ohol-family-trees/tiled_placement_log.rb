require 'ohol-family-trees/arc'
require 'json'

module OHOLFamilyTrees
  class TiledPlacementLog
    MaxLog = 24*60*60

    attr_reader :tiles
    attr_reader :arc

    attr_reader :server
    attr_accessor :s_start
    attr_accessor :s_end
    attr_accessor :s_base
    attr_reader :seed

    def initialize(server, st, sd, arc = Arc.new(server, st, st, sd))
      @server = server
      @s_base = 0
      @s_start = st
      @s_end = st
      @seed = sd

      @tiles = Hash.new {|h,k| h[k] = Tile.new(k,s_start)}
      @arc = arc
    end

    def next_span(st)
      self.class.new(server, st, seed, arc).copy_key(self)
    end

    def updated_tiles
      tiles.select {|coord,tile| tile.updated}
    end

    def tile_index
      tiles.values.reject(&:empty?).map {|tile|
        [tile.tilex,tile.tiley,(tile.updated ? s_end : tile.time)]
      }
    end

    def placements
      tiles.transform_values {|tile| tile.placements}
    end

    def copy_key(previous)
      @s_base = previous.s_end
      previous.tiles.each_pair {|coords, tile| tiles[coords] = tile.copy }
      self
    end

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
      out = new(server, 0, seed)
      if options[:base]
        p "resume from #{options[:base].s_end}"
        out.copy_key(options[:base])
      end
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start && log.s_start < Arc::SplitArcsBefore
            yield out
            out = new(server, log.s_start, seed)
          end
          start = log
          if out.arc.s_start == 0
            out.arc.s_start = start.s_start
          end
          if out.s_start == 0
            out.s_start = start.s_start
          end
          out.arc.s_end = start.s_start
          out.s_end = start.s_start
        elsif log.kind_of?(Maplog::Placement)
          log.ms_start = start.ms_start
          if breakpoints.any? && log.s_time > breakpoints.first
            breakpoints.shift
            yield out
            out = out.next_span(log.s_time)
          end

          out.arc.s_end = log.s_time
          out.s_end = log.s_time
          tilex = log.x / tile_width
          #(-tileY - 1) * tile_width = log.y
          #-tileY - 1 = log.y / tile_width
          #-tileY = log.y / tile_width + 1
          tiley = -(log.y / tile_width + 1)
          tile = out.tiles[[tilex,tiley]]
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
            tile = out.tiles[coord]
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
      yield out
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

  class Tile
    attr_reader :floors
    attr_reader :objects
    attr_reader :placements

    attr_reader :updated
    attr_reader :coords
    attr_reader :time

    def initialize(cor, t)
      @updated = false
      @coords = cor
      @time = t
      @floors = {}
      @objects = {}
      @placements = []
    end

    def copy_key(tile)
      @coords = tile.coords
      @floors = tile.floors
      @objects = tile.objects
      self
    end

    def copy
      self.class.new(coords, time).copy_key(self)
    end

    def empty?
      floors.empty? && objects.empty?
    end

    def tilex
      coords[0]
    end

    def tiley
      coords[1]
    end

    def floor(x, y)
      floors["#{x} #{y}"]
    end

    def remove_floor(x, y)
      @updated = true
      floors.delete("#{x} #{y}")
    end

    def set_floor(x, y, object)
      @updated = true
      floors["#{x} #{y}"] = object
    end

    def object(x, y)
      objects["#{x} #{y}"]
    end

    def set_object(x, y, object)
      @updated = true
      objects["#{x} #{y}"] = object
    end

    def add_placement(log)
      placements << log
    end
  end
end
