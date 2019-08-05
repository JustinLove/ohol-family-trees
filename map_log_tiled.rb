require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'date'
require 'fileutils'

include OHOLFamilyTrees

FileUtils.mkdir_p('output/maplog')

tile_width = 256

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('1151446675seed')
    map = Hash.new {|h,k| h[k] = []}
    p logfile
    file = logfile.open
    while line = file.gets
      log = Maplog.create(line)

      if log.kind_of?(Maplog::Placement)
        tilex = log.x / tile_width
        tiley = (-log.y / tile_width)
        map[[tilex,tiley]] << log
      end
    end
    basename = logfile.path.split(/[\/]/)[1].sub('.txt', '')
    map.each do |coords,tile|
      tilex, tiley = *coords
      FileUtils.mkdir_p("output/maplog/#{basename}/#{tilex}")
      File.open("output/maplog/#{basename}/#{tilex}/#{tiley}.txt", 'wb') do |out|
        tile.each do |logline|
          out << "#{logline.ms_offset} #{logline.x} #{logline.y} #{logline.object}\n"
        end
      end
    end
  end

end
