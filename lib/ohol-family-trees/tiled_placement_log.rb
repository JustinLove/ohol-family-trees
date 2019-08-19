require 'ohol-family-trees/arc'
require 'json'

module OHOLFamilyTrees
  class TiledPlacementLog
    attr_reader :floors
    attr_reader :objects
    attr_reader :placements
    attr_accessor :s_end

    def initialize
      @objects = Hash.new {|h,k| h[k] = {}}
      @floors = Hash.new {|h,k| h[k] = {}}
      @placements = Hash.new {|h,k| h[k] = []}
      @s_end = 0
    end

    def self.read(logfile, tile_width, options = {})
      excluded = 0
      floor_removal = options[:floor_removal] || {}
      min_size = options[:min_size] || 0
      object_size = options[:object_size]
      object_over = options[:object_over] || Hash.new {|h,k| h[k] = ObjectOver.new(2, 2, 2, 4)}
      start = nil
      file = logfile.open
      previous = nil
      tiled = []
      out = new
      tiled << out
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start && log.s_start < Arc::SplitArcsBefore
            out = new
            tiled << out
          end
          start = log
          out.s_end = start.s_start
        elsif log.kind_of?(Maplog::Placement)
          log.ms_start = start.ms_start
          out.s_end = log.s_time
          tilex = log.x / tile_width
          #(-tileY - 1) * tile_width = log.y
          #-tileY - 1 = log.y / tile_width
          #-tileY = log.y / tile_width + 1
          tiley = -(log.y / tile_width + 1)
          object = log.object
          if log.floor?
            occupant = out.floors[[tilex,tiley]]["#{log.x} #{log.y}"]
            out.placements[[tilex,tiley]] << log
            out.floors[[tilex,tiley]]["#{log.x} #{log.y}"] = object
          else
            occupant = out.objects[[tilex,tiley]]["#{log.x} #{log.y}"]
            removes = floor_removal[object]
            if removes
              if out.floors[[tilex,tiley]]["#{log.x} #{log.y}"] == removes &&
                 previous.object == "0" &&
                 previous.x == log.x &&
                 previous.y == log.y &&
                 previous.ms_offset == log.ms_offset
                out.floors[[tilex,tiley]].delete("#{log.x} #{log.y}")
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

            out.placements[[tilex,tiley]] << log
            out.objects[[tilex,tiley]]["#{log.x} #{log.y}"] = object
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
          overs.each do |tile|
            out.placements[tile] << log
            if log.floor?
              # overkill, but I don't want separate bounds for floors, bearskin can hang over
              out.floors[tile]["#{log.x} #{log.y}"] = object
            else
              out.objects[tile]["#{log.x} #{log.y}"] = object
            end
          end
        end
        previous = log
      end
      p "excluded #{excluded} objects"
      tiled
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
