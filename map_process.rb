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

arcs = ArcList.new(filesystem, PlacementPath)

#final_placements = OutputFinalPlacements.new(PlacementPath, filesystem, objects)

#maplog = OutputMaplog.new(MaplogPath, filesystem, objects)

MaplogCache::Servers.new.each do |logs|
  #p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  prior = nil
  current_arc = nil
  logs.each do |logfile|
    #next unless logfile.timestamp >= 1573895673

    if logfile.placements?
      if prior and logfile.merges_with?(prior)
      else
        p "merge break at #{logfile.timestamp}"
        if current_arc
          current_arc.s_end = logfile.timestamp
        end
        current_arc = Arc.new(0, logfile.timestamp+1, nil, logfile.seed)
        arcs << current_arc
      end

      if prior and false
        gap = (logfile.timestamp - prior.timestamp) / (60.0 * 60.0)
        p "#{prior.approx_log_time} #{gap} #{logfile.approx_log_time}"
        unless (23.99..24.01).member?(gap)
          p "#{gap} gap at #{logfile.timestamp}"
        end
      end

      prior = logfile
    end

    if logfile.seed_only?
      p "seed change at #{logfile.timestamp}"
      if current_arc
        current_arc.s_end = logfile.timestamp
      end
      current_arc = Arc.new(0, logfile.timestamp+1, nil, logfile.seed)
      arcs << current_arc
    end
  end
  arcs.checkpoint

  prior = nil
  logs.each do |logfile|
    next unless logfile.placements?

    #next unless logfile.path.match('000seed')
    #next unless logfile.path.match('1151446675seed') # small file
    #next unless logfile.path.match('1521396640seed') # two arcs in one file
    #next unless logfile.path.match('588415882seed') # one arc with multiple start times
    #next unless logfile.path.match('2680185702seed') # multiple files one seed
    #next unless logfile.path.match('3019284048seed') # multiple files one seed, smaller dataset
    #next unless logfile.path.match('1574835680time') # small with player ids
    next unless logfile.timestamp >= 1573895673


    base = nil
    if prior and logfile.merges_with?(prior)
      #p "#{logfile.path} merges with #{prior.path}"
      base = prior
    end
    if prior
      #p (logfile.timestamp - prior.timestamp) / (60.0 * 60.0)
    end
    prior = logfile

    #breakpoints = logfile.breakpoints

    #final_placements.process(logfile, {:basefile => base, :breakpoints => breakpoints})
    #maplog.process(logfile, {:breakpoints => breakpoints})
  end
end
