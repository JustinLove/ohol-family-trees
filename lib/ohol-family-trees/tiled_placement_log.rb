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

    def self.read(logfile, tile_width, floor_removal)
      start = nil
      ms_last_offset = 0
      file = logfile.open
      previous = nil
      tiled = []
      out = new
      tiled << out
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start && log.s_start < Arc::SplitArcsBefore
            out.s_end = start.s_start + (ms_last_offset/1000).round
            out = new
            tiled << out
          end
          start = log
          ms_last_offset = 0
        elsif log.kind_of?(Maplog::Placement)
          ms_last_offset = log.ms_offset
          tilex = log.x / tile_width
          #(-tileY - 1) * tile_width = log.y
          #-tileY - 1 = log.y / tile_width
          #-tileY = log.y / tile_width + 1
          tiley = -(log.y / tile_width + 1)
          object = log.object
          out.placements[[tilex,tiley]] << log
          if log.floor?
            out.floors[[tilex,tiley]]["#{log.x} #{log.y}"] = object
          else
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
            out.objects[[tilex,tiley]]["#{log.x} #{log.y}"] = object
          end
          tx = log.x % tile_width
          ty = log.y % tile_width
          overx = 0
          overy = 0
          if tx <= 2
            overx = -1
          elsif tx >= (tile_width - 2)
            overx = 1
          end
          if ty <= 2
            overy = 1
          elsif ty >= (tile_width - 4)
            overy = -1
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
      out.s_end = start.s_start + (ms_last_offset/1000).round
      tiled
    end
  end
end
