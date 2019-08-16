require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/arc'
require 'date'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output/keyplace'
SplitArcsBefore = DateTime.parse('2019-07-31 12:56-0500').to_time.to_i

FileUtils.mkdir_p(OutputDir)

def write_tiles(objects, floors, dir, zoom)
  p dir
  (objects.keys | floors.keys).each do |coords|
    tilex, tiley = *coords
    FileUtils.mkdir_p("#{OutputDir}/#{dir}/#{zoom}/#{tilex}")
    File.open("#{OutputDir}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt", 'wb') do |out|
      floors[coords].each do |key,value|
        out << "#{key} #{value}\n"
      end
      objects[coords].each do |key,value|
        out << "#{key} #{value}\n"
      end
    end
  end
end

floorRemoval = {}
objectMaster = JSON.parse(File.read('cache/objects.json'))
objectMaster['floorRemovals'].each do |transition|
  floorRemoval[transition['newTargetID']] = 'f' + transition['targetID']
end

ZoomLevels = 24..24

ZoomLevels.each do |zoom|
  tile_width = 2**(32 - zoom)

  MaplogCache::Servers.new.each do |logs|
    p logs

    #server = logs.server.sub('.onehouronelife.com', '')

    logs.each do |logfile|
      #next unless logfile.path.match('000seed')
      #next unless logfile.path.match('1151446675seed') # small file
      #next unless logfile.path.match('1521396640seed') # two arcs in one file
      #next unless logfile.path.match('588415882seed') # one arc with multiple start times
      objects = Hash.new {|h,k| h[k] = {}}
      floors = Hash.new {|h,k| h[k] = {}}
      start = nil
      ms_last_offset = 0
      p logfile
      file = logfile.open
      previous = nil
      while line = file.gets
        log = Maplog.create(line)

        if log.kind_of?(Maplog::ArcStart)
          if log.s_start < SplitArcsBefore
            if start && objects.length > 0
              arc = Arc.new(0, start.s_start, (ms_last_offset/1000).round, 0)
              write_tiles(objects, floors, arc.s_end, zoom)
            end
            objects = Hash.new {|h,k| h[k] = {}}
            floors = Hash.new {|h,k| h[k] = {}}
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
          if log.floor?
            floors[[tilex,tiley]]["#{log.x} #{log.y}"] = object
          else
            removes = floorRemoval[object]
            if removes
              if floors[[tilex,tiley]]["#{log.x} #{log.y}"] == removes &&
                 previous.object == "0" &&
                 previous.x == log.x &&
                 previous.y == log.y &&
                 previous.ms_offset == log.ms_offset
                floors[[tilex,tiley]].delete("#{log.x} #{log.y}")
              end
            end
            objects[[tilex,tiley]]["#{log.x} #{log.y}"] = object
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
            if log.floor?
              # overkill, but I don't want separate bounds for floors, bearskin can hang over
              floors[tile]["#{log.x} #{log.y}"] = object
            else
              objects[tile]["#{log.x} #{log.y}"] = object
            end
          end
        end
        previous = log
      end
      if start && objects.length > 0
        arc = Arc.new(0, start.s_start, (ms_last_offset/1000).round, 0)
        write_tiles(objects, floors, arc.s_end, zoom)
      end
    end
  end
end
