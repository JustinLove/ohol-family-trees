require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'date'
require 'fileutils'

include OHOLFamilyTrees

output_dir = 'output/mapfinalimage'

FileUtils.mkdir_p(output_dir)

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
        ox = log.x - (tilex * tile_width)
        oy = -(log.y - (-tiley * tile_width))
        if map[[tilex,tiley]][ox].nil?
          map[[tilex,tiley]][ox] = []
        end
        map[[tilex,tiley]][ox][oy] = log.object
      end
    end
    basename = logfile.path.split(/[\/]/)[1].sub('.txt', '')
    map.each do |coords,tile|
      tilex, tiley = *coords
      FileUtils.mkdir_p("#{output_dir}/#{basename}/#{tilex}")
      list = []
      (0..255).each do |x|
        (0..255).each do |y|
          if tile[x] && tile[x][y]
            list << tile[x][y]
          else
            list << '.'
          end
        end
      end
      File.open("#{output_dir}/#{basename}/#{tilex}/#{tiley}.txt", 'wb') do |out|
        out << list.join(' ')
      end
    end
  end
end