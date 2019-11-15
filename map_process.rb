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
OutputBucket = 'wondible-com-ohol-tiles'


filesystem = FilesystemGroup.new([
  FilesystemLocal.new(OutputDir),
  #FilesystemS3.new(OutputBucket),
])

#filesystem.list('kp/1573263189/24').each do |path|
  #p path
#end
#exit

objects = ObjectData.new
filesystem.read('static/objects.json') do |f|
  objects.read!(f.read)
end

raise "no object data" unless objects.object_size.length > 0

final_placements = OutputFinalPlacements.new(PlacementPath, filesystem, objects)

maplog = OutputMaplog.new(MaplogPath, filesystem, objects)

MaplogCache::Servers.new.each do |logs|
  #p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  prior = nil

  logs.each do |logfile|
    base = nil
    if prior and logfile.merges_with?(prior)
      base = prior
    end
    prior = logfile

    #next unless logfile.path.match('000seed')
    #next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    next unless logfile.path.match('2680185702seed') # multiple files one seed
    #next unless logfile.path.match('3019284048seed') # multiple files one seed, smaller dataset

    final_placements.process(logfile, base)
    #maplog.process(logfile, base)
  end
end
