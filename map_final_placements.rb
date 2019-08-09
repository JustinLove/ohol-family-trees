require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/arc'
require 'date'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output/keyplace'

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

ZoomLevels = 24..28
FullDetail = 28

objectSize = {}
objectMaster = JSON.parse(File.read('cache/objects.json'))
objectMaster['ids'].each_with_index do |id,i|
  bounds = objectMaster['bounds'][i]
  objectSize[id] = [bounds[2] - bounds[0] - 30, bounds[3] - bounds[1] - 30].min
end


ZoomLevels.each do |zoom|
  tile_width = 2**(32 - zoom)
  cellSize = 2**(zoom - 24)
  if zoom >= FullDetail
    minSize = 0
  else
    minSize = 1.5 * (128/cellSize)
  end

  MaplogCache::Servers.new.each do |logs|
    p logs
    excluded = 0

    #server = logs.server.sub('.onehouronelife.com', '')

    logs.each do |logfile|
      #next unless logfile.path.match('000seed')
      #next unless logfile.path.match('1151446675seed')
      #next unless logfile.path.match('1521396640seed')
      objects = Hash.new {|h,k| h[k] = {}}
      floors = Hash.new {|h,k| h[k] = {}}
      start = nil
      ms_last_offset = 0
      p logfile
      file = logfile.open
      while line = file.gets
        log = Maplog.create(line)

        if log.kind_of?(Maplog::ArcStart)
          if start && objects.length > 0
            arc = Arc.new(0, start.s_start, (ms_last_offset/1000).round, 0)
            write_tiles(objects, floors, arc.s_end, zoom)
          end
          objects = Hash.new {|h,k| h[k] = {}}
          floors = Hash.new {|h,k| h[k] = {}}
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
            size = objectSize[log.id]
            if !size || size <= minSize
              previous = objects[[tilex,tiley]]["#{log.x} #{log.y}"]
              if size
                #p log.id
                excluded += 1
              end
              if previous && previous != "0"
                object = "0"
              else
                next
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
      end
      if start && objects.length > 0
        arc = Arc.new(0, start.s_start, (ms_last_offset/1000).round, 0)
        write_tiles(objects, floors, arc.s_end, zoom)
      end
      p excluded
    end
  end
end
