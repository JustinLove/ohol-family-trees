require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog_list'
require 'ohol-family-trees/object_data'
require 'ohol-family-trees/output_final_placements'
require 'ohol-family-trees/output_maplog'
require 'ohol-family-trees/output_activity_map'
require 'ohol-family-trees/seed_break'
require 'ohol-family-trees/logfile_context'
require 'ohol-family-trees/filesystem_local'
require 'ohol-family-trees/filesystem_s3'
require 'ohol-family-trees/filesystem_group'
require 'fileutils'
require 'json'
require 'set'

include OHOLFamilyTrees

#OutputDir = 'output'
OutputDir = 'd:/dev/ohol-map/public'
OutputBucket = 'wondible-com-ohol-tiles'
MaplogArchive = 'publicMapChangeData'


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

#MaplogCache::Servers.new('cache/mapfake/').each do |logs|
MaplogCache::Servers.new.each do |logs|
  #p logs
  servercode = "17"

  placement_path = "pl/#{servercode}"
  maplog_path = "pl/#{servercode}"
  actmap_path = "pl/#{servercode}"

  list = MaplogList::Logs.new(filesystem, "#{placement_path}/file_list.json", "publicMapChangeData/")
  #p list.files.length
  updated_files = Set.new
  list.update_from(logs) do |logfile|
    updated_files << logfile.path
  end
  #p updated_files
  #p list.files.length
  #p list.files

  final_placements = OutputFinalPlacements.new(placement_path, filesystem, objects)

  maplog = OutputMaplog.new(maplog_path, filesystem, objects)

  actmap = OutputActivityMap.new(actmap_path, filesystem)

  manual_resets = SeedBreak.read_manual_resets(filesystem, "#{placement_path}/manual_resets.txt")
  seeds = SeedBreak.process(list, manual_resets)
  seeds.save(filesystem, "#{placement_path}/seeds.json")

  context = LogfileContext.process(seeds, list)

  list.each do |logfile|
    next unless logfile.placements?

    if logs.has?(logfile.path)
      logfile = logs.get(logfile.path)
    end

    #next unless logfile.path.match('000seed')
    next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    #next unless logfile.path.match('3019284048seed') # multiple files one seed, smaller dataset
    #next unless logfile.path.match('1124586729seed') # microspan at end
    #next unless logfile.path.match('4088407786seed') # single zero byte file
    #next unless logfile.path.match('1574835680time') # small with player ids
    #next unless logfile.path.match('1576038671time') # double start times at beginning
    #next unless logfile.timestamp >= 1573895673
    #next unless logfile.timestamp >= 1576038671

    if false
      if updated_files.member?(logfile.path)
        p 'updated file', logfile.path
        filesystem.write(MaplogArchive + '/' + logfile.path) do |archive|
          IO::copy_stream(logfile.open, archive)
        end
      end
    end
    if false
      final_placements.process(logfile, context[logfile.path])
    end
    if false
      final_placements.timestamp_fixup(logfile)
    end
    if false
      maplog.process(logfile)
    end
    if false
      maplog.timestamp_fixup(logfile)
    end
    if true
      actmap.process(logfile)
    end
  end

  #list.checkpoint
end
