require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/tiled_placement_log'
require 'ohol-family-trees/object_data'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output'
MaplogDir = "#{OutputDir}/ml"
ProcessedPath = "#{MaplogDir}/processed.json"

FileUtils.mkdir_p(OutputDir)

def write_tiles(map, dir, zoom)
  p dir
  map.each do |coords,tile|
    tilex, tiley = *coords
    next if tile.empty?
    FileUtils.mkdir_p("#{MaplogDir}/#{dir}/#{zoom}/#{tilex}")
    File.open("#{MaplogDir}/#{dir}/#{zoom}/#{tilex}/#{tiley}.txt", 'wb') do |out|
      last_x = 0
      last_y = 0
      last_time = 0
      tile.each do |logline|
        out << "#{(logline.ms_time - last_time)/10} #{logline.x - last_x} #{logline.y - last_y} #{logline.object}\n"
        last_time = logline.ms_time
        last_x = logline.x
        last_y = logline.y
      end
    end
  end
end

objects = ObjectData.new('cache/objects.json').read!

ZoomLevels = 24..27
FullDetail = 27

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
    #next unless logfile.path.match('1911649160seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    next if processed[logfile.path] && logfile.date.to_i <= processed[logfile.path]['time']
    processed[logfile.path] = {
      'time' => Time.now.to_i,
      'paths' => []
    }

    p logfile

    ZoomLevels.each do |zoom|
      tile_width = 2**(32 - zoom)
      cellSize = 2**(zoom - 24)
      if zoom >= FullDetail
        min_size = 0
      else
        min_size = 1.5 * (128/cellSize)
      end

      p zoom

      TiledPlacementLog.read(logfile, tile_width, {
          :floor_removal => objects.floor_removal,
          :min_size => min_size,
          :object_size => objects.object_size,
          :object_over => objects.object_over,
        }).each do |tiled|

        write_tiles(tiled.placements, tiled.arc.s_end, zoom)

        processed[logfile.path]['paths'] << "#{tiled.arc.s_end.to_s}/#{zoom}"
        #p processed
      end
    end

    File.write(ProcessedPath, JSON.pretty_generate(processed))
  end
end
