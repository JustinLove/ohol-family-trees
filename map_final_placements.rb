require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'date'
require 'fileutils'

include OHOLFamilyTrees

output_dir = 'output/keyplace'

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
        #(-tileY - 1) * tile_width = log.y
        #-tileY - 1 = log.y / tile_width
        #-tileY = log.y / tile_width + 1
        tiley = -(log.y / tile_width + 1)
        #if log.y.abs < 2
          #p [log.x, log.y, tilex, tiley]
        #end
        map[[tilex,tiley]]["#{log.x} #{log.y}"] = log.object
      end
    end
    dir = logfile.timestamp.to_s
    map.each do |coords,tile|
      tilex, tiley = *coords
      FileUtils.mkdir_p("#{output_dir}/#{dir}/#{tilex}")
      File.open("#{output_dir}/#{dir}/#{tilex}/#{tiley}.txt", 'wb') do |out|
        tile.each do |key,value|
          out << "#{key} #{value}\n"
        end
      end
    end
  end

end
