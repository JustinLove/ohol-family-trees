require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'date'
require 'fileutils'

include OHOLFamilyTrees

output_dir = 'output/mapfinalplacements'

FileUtils.mkdir_p(output_dir)

tile_width = 256

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('1151446675seed')
    map = Hash.new {|h,k| h[k] = {}}
    p logfile
    file = logfile.open
    while line = file.gets
      log = Maplog.create(line)

      if log.kind_of?(Maplog::Placement)
        tilex = log.x / tile_width
        tiley = (-log.y / tile_width)
        map[[tilex,tiley]]["#{log.x} #{log.y}"] = log.object
      end
    end
    basename = logfile.path.split(/[\/]/)[1].sub('.txt', '')
    map.each do |coords,tile|
      tilex, tiley = *coords
      FileUtils.mkdir_p("#{output_dir}/#{basename}/#{tilex}")
      File.open("#{output_dir}/#{basename}/#{tilex}/#{tiley}.txt", 'wb') do |out|
        tile.each do |key,value|
          out << "#{key} #{value}\n"
        end
      end
    end
  end

end
