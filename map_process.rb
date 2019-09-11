require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/object_data'
require 'ohol-family-trees/output_final_placements'
require 'ohol-family-trees/output_maplog'
require 'ohol-family-trees/filesystem_local'
require 'ohol-family-trees/filesystem_s3'
require 'ohol-family-trees/filesystem_group'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

PlacementPath = "kp"
MaplogPath = "ml"

OutputDir = 'output'
OutputBucket = 'wondible-com-ohol-tiles'


filesystem = FilesystemGroup.new([
  FilesystemLocal.new(OutputDir),
  #FilesystemS3.new(OutputBucket),
])

objects = ObjectData.new
filesystem.read('static/objects.json') do |f|
  objects.read!(f.read)
end

raise "no object data" unless objects.object_size.length > 0

final_placements = OutputFinalPlacements.new(PlacementPath, filesystem, objects)

maplog = OutputMaplog.new(MaplogPath, filesystem, objects)

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('000seed')
    #next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed

    final_placements.process(logfile)
    maplog.process(logfile)
  end
end
