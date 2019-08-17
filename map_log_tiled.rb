require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/tiled_placement_log'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output/maplogtest'

FileUtils.mkdir_p(OutputDir)

def write_tiles(map, dir, zoom)
  p dir
  map.each do |coords,tile|
    tilex, tiley = *coords
    FileUtils.mkdir_p("#{OutputDir}/#{dir}/#{zoom}/#{tilex}")
    File.open("#{OutputDir}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt", 'wb') do |out|
      last_x = 0
      last_y = 0
      last_offset = 0
      tile.each do |logline|
        out << "#{(logline.ms_offset - last_offset)/10} #{logline.x - last_x} #{logline.y - last_y} #{logline.object}\n"
        last_offset = logline.ms_offset
        last_x = logline.x
        last_y = logline.y
      end
    end
  end
end

object_master = JSON.parse(File.read('cache/objects.json'))

object_size = {}
object_master['ids'].each_with_index do |id,i|
  bounds = object_master['bounds'][i]
  object_size[id] = [bounds[2] - bounds[0] - 30, bounds[3] - bounds[1] - 30].min
end

floor_removal = {}
object_master['floorRemovals'].each do |transition|
  floor_removal[transition['newTargetID']] = 'f' + transition['targetID']
end

ZoomLevels = 24..24
FullDetail = 24

ZoomLevels.each do |zoom|
  tile_width = 2**(32 - zoom)
  cellSize = 2**(zoom - 24)
  if zoom >= FullDetail
    min_size = 0
  else
    min_size = 1.5 * (128/cellSize)
  end

  MaplogCache::Servers.new.each do |logs|
    p logs

    #server = logs.server.sub('.onehouronelife.com', '')

    logs.each do |logfile|
      #next unless logfile.path.match('000seed')
      #next unless logfile.path.match('1151446675seed') # small file
      #next unless logfile.path.match('1521396640seed') # two arcs in one file
      next unless logfile.path.match('588415882seed') # one arc with multiple start times
      p logfile
      TiledPlacementLog.read(logfile, tile_width, {
          :floor_removal => floor_removal,
          :min_size => min_size,
          :object_size => object_size,
        }).each do |tiled|
        write_tiles(tiled.placements, tiled.s_end, zoom)
      end
    end
  end
end
