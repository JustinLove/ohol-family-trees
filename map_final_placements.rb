require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/tiled_placement_log'
require 'ohol-family-trees/object_data'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output'
PlacementDir = "#{OutputDir}/kp"
ArcPath = "#{OutputDir}/arcs.json"
ProcessedPath = "#{PlacementDir}/processed.json"

FileUtils.mkdir_p(PlacementDir)

def write_tiles(objects, floors, dir, zoom)
  p dir
  (objects.keys | floors.keys).each do |coords|
    tilex, tiley = *coords
    next if floors[coords].empty? && objects[coords].empty?
    FileUtils.mkdir_p("#{PlacementDir}/#{dir}/#{zoom}/#{tilex}")
    File.open("#{PlacementDir}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt", 'wb') do |out|
      floors[coords].each do |key,value|
        out << "#{key} #{value}\n"
      end
      objects[coords].each do |key,value|
        out << "#{key} #{value}\n"
      end
    end
  end
end

objects = ObjectData.new('cache/objects.json').read!

ZoomLevels = 24..24

arcs = {}
if File.exist?(ArcPath)
  list = JSON.parse(File.read(ArcPath))
  list.each do |arc|
    arcs[arc['start'].to_s] = arc
  end
end
#p arcs

processed = {}
if File.exist?(ProcessedPath)
  processed = JSON.parse(File.read(ProcessedPath))
end
#p processed

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('000seed')
    #next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    next if processed[logfile.path] && logfile.date.to_i <= processed[logfile.path]['time']
    processed[logfile.path] = {
      'time' => Time.now.to_i,
      'paths' => []
    }

    p logfile

    ZoomLevels.each do |zoom|
      tile_width = 2**(32 - zoom)

      TiledPlacementLog.read(logfile, tile_width, {
          :floor_removal => objects.floor_removal,
          :object_over => objects.object_over,
        }).each do |tiled|

        arcs[tiled.arc.s_start.to_s] = {
          'start' => tiled.arc.s_start,
          'end' => tiled.arc.s_end,
          'seed' => tiled.arc.seed,
        }
        #p arcs

        write_tiles(tiled.objects, tiled.floors, tiled.arc.s_end, zoom)

        processed[logfile.path]['paths'] << tiled.arc.s_end.to_s
        #p processed
      end
    end

    File.write(ArcPath, JSON.pretty_generate(arcs.values.sort_by {|arc| arc['start']}))
    File.write(ProcessedPath, JSON.pretty_generate(processed))
  end
end
