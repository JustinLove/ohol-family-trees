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
      tile.each do |logline|
        out << "#{logline.ms_offset} #{logline.x} #{logline.y} #{logline.object}\n"
      end
    end
  end
end

floor_removal = {}
object_master = JSON.parse(File.read('cache/objects.json'))
object_master['floorRemovals'].each do |transition|
  floor_removal[transition['newTargetID']] = 'f' + transition['targetID']
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
      p logfile
      TiledPlacementLog.read(logfile, tile_width, floor_removal).each do |tiled|
        write_tiles(tiled.placements, tiled.s_end, zoom)
      end
    end
  end
end
