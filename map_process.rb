require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/object_data'
require 'ohol-family-trees/output_final_placements'
require 'ohol-family-trees/output_maplog'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output'
PlacementDir = "#{OutputDir}/kp"
MaplogDir = "#{OutputDir}/ml"

objects = ObjectData.new('cache/objects.json').read!

final_placements = OutputFinalPlacements.new(PlacementDir, objects)
maplog = OutputMaplog.new(MaplogDir, objects)

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('000seed')
    #next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    #next if processed[logfile.path] && logfile.date.to_i <= processed[logfile.path]['time']

    p logfile

    final_placements.process(logfile)
    maplog.process(logfile)
  end
end
