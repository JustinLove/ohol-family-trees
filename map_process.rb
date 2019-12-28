require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/object_data'
require 'ohol-family-trees/output_final_placements'
require 'ohol-family-trees/output_maplog'
require 'ohol-family-trees/seed_break'
require 'ohol-family-trees/filesystem_local'
require 'ohol-family-trees/filesystem_s3'
require 'ohol-family-trees/filesystem_group'
require 'fileutils'
require 'json'

include OHOLFamilyTrees

OutputDir = 'output'
#OutputDir = 'd:/games/ohol-map/public'
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

MaplogCache::Servers.new.each do |logs|
  #p logs
  servercode = logs.servercode

  placement_path = "pl/#{servercode}"
  maplog_path = "pl/#{servercode}"

  final_placements = OutputFinalPlacements.new(placement_path, filesystem, objects)

  maplog = OutputMaplog.new(maplog_path, filesystem, objects)


  manual_resets = []
  filesystem.read("#{placement_path}/manual_resets.txt") do |f|
    while line = f.gets
      manual_resets << line.to_i
    end
  end
  #p manual_resets
  seeds = SeedBreak.process(logs, manual_resets)
  seeds.save(filesystem, "#{placement_path}/seeds.json")

  prior_logfile = nil
  prior_arc = nil
  root = nil
  logs.each do |logfile|
    next unless logfile.placements?

    #next unless logfile.path.match('000seed')
    #next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    next unless logfile.path.match('3019284048seed') # multiple files one seed, smaller dataset
    #next unless logfile.path.match('1124586729seed') # microspan at end
    #next unless logfile.path.match('1574835680time') # small with player ids
    #next unless logfile.path.match('1576038671time') # double start times at beginning
    #next unless logfile.timestamp >= 1573895673
    #next unless logfile.timestamp >= 1576038671

    arc = seeds.arc_at(logfile.timestamp+1)

    base = nil
    if (arc == prior_arc || logfile.timestamp == 1574102503) && prior_logfile && logfile.merges_with?(prior_logfile)
      p "#{logfile.path} merges with #{prior_logfile.path}"
      base = prior_logfile
    else
      p "#{logfile.path} is root"
      root = logfile
    end
    if prior_logfile
      #p (logfile.timestamp - prior_logfile.timestamp) / (60.0 * 60.0)
    end
    prior_logfile = logfile
    prior_arc = arc

    if true
      final_placements.process(logfile, {
        :rootfile => root,
        :basefile => base})
    end
    if false
      maplog.process(logfile)
    end
  end
end
