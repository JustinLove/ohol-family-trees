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

PlacementPath = "kptest"
MaplogPath = "mltest"

OutputDir = 'output'
PlacementDir = "#{OutputDir}/#{PlacementPath}"
MaplogDir = "#{OutputDir}/#{MaplogPath}"

OutputBucket = 'wondible-com-ohol-tiles'

objects = ObjectData.new('cache/objects.json').read!

filesystem = FilesystemGroup.new([
  FilesystemLocal.new(OutputDir),
  FilesystemS3.new(OutputBucket),
])

final_placements = OutputFinalPlacements.new(OutputDir, PlacementPath, filesystem, objects)

=begin
maplog_system = FilesystemGroup.new([
  FilesystemLocal.new(PlacementDir),
  FilesystemS3.new(PlacementDir),
])
maplog = OutputMaplog.new(MaplogDir, maplog_system, objects)
=end

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('000seed')
    next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    #next if processed[logfile.path] && logfile.date.to_i <= processed[logfile.path]['time']

    p logfile

    final_placements.process(logfile)
    #maplog.process(logfile)
  end
end
