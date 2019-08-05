require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'date'
require 'fileutils'

include OHOLFamilyTrees

FileUtils.mkdir_p('output/map')

MaplogCache::Servers.new.each do |logs|
  p logs

  #server = logs.server.sub('.onehouronelife.com', '')

  logs.each do |logfile|
    #next unless logfile.path.match('1151446675seed')
    map = {}
    p logfile
    file = logfile.open
    while line = file.gets
      log = Maplog.create(line)

      if log.kind_of?(Maplog::Placement)
        map["#{log.x} #{log.y}"] = log.object
      end
    end
    basename = logfile.path.split(/[\/]/)[1]
    list = []
    map.each_pair do |key,value|
      list << ("#{key} #{value}\n")
    end
    list.sort!
    File.open("output/map/#{basename}", 'wb') do |out|
      list.each do |l|
        out << l
      end
    end
  end

end
