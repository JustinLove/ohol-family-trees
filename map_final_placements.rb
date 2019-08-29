require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/tiled_placement_log'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output/keyplaceover'

FileUtils.mkdir_p(OutputDir)

def write_tiles(objects, floors, dir, zoom)
  p dir
  (objects.keys | floors.keys).each do |coords|
    tilex, tiley = *coords
    next if floors[coords].empty? && objects[coords].empty?
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

object_master = JSON.parse(File.read('cache/objects.json'))

object_size = {}
object_over = {}
object_master['ids'].each_with_index do |id,i|
  bounds = object_master['bounds'][i]
  object_over[id] = TiledPlacementLog::ObjectOver.new(*bounds.map {|b| (b/128.0).round.abs})
  object_size[id] = [bounds[2] - bounds[0] - 30, bounds[3] - bounds[1] - 30].min
end

floor_removal = {}
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
      #next unless logfile.path.match('1315059099seed')
      #next unless logfile.path.match('2072746342seed')
      #next unless logfile.path.match('2739539232seed')
      #next unless logfile.path.match('5224995seed')
      #next unless logfile.path.match('980020880seed')
      #next unless logfile.path.match('3239436732seed')
      next unless logfile.path.match('2680185702seed')
      p logfile
      TiledPlacementLog.read(logfile, tile_width, {
          :floor_removal => floor_removal,
          :object_over => object_over,
        }).each do |tiled|
        write_tiles(tiled.objects, tiled.floors, tiled.s_end, zoom)
      end
    end
  end
end
