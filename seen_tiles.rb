require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/lifelog_cache'
require 'date'
require 'json'
require 'progress_bar'

include OHOLFamilyTrees

zoom_levels = 1..24
#zoom_levels = 24..24

zoom_levels.each do |zoom|
  tile_width = 2**(32 - zoom)
  around = 500 / tile_width
  p around
  range = (-around..around)
  LifelogCache::Servers.new.each do |logs|
  #do
    #dir = "lifeLog_bigserver2.onehouronelife.com"
    lives = History.new

    #p dir

    server = logs.server

    # level 29:
    #next if server.match('big')
    #next if server.match('server1')
    #next if server == 'server2'

    p "#{server} #{zoom}"

    #files = Dir.entries("cache/"+dir).reject {|path| path.match('_names.txt')}.size
    bar = ProgressBar.new()

    chunk_size = 10000000
    chunk_number = 0
    sparse = Hash.new {|h,k| h[k] = 0}

    from_time = (Date.today - 7).to_time
    to_time = (Date.today - 0).to_time
    lives.load_server(logs, ((from_time - 60*60*24*1)..(to_time + 60*60*24*1))) do |logfile|
    #lives.load_dir("cache/"+dir) do |path|
    #path = "cache/lifeLog_bigserver2.onehouronelife.com/2019_05May_29_Wednesday.txt"
    #do
      next if logfile.names?

      #p path
      file = logfile.open
      i = 0
      while line = file.gets
        i += 1
        log = Lifelog.create(line, 0, server)

        x, y = log.coords
        unless x.nil? || y.nil?
          tilex = x / tile_width
          tiley = (-y / tile_width)
          #p [x, y, tilex, tiley]
          range.each do |dx|
            range.each do |dy|
              sparse["#{tilex + dx} #{tiley + dy}"] += 1
            end
          end
        end
      end

      bar.increment!

      if sparse.size > chunk_size
        p "writing #{sparse.size}"
        File.open("output/tilelists_update/#{server}_#{zoom}_#{chunk_number}_tiles.txt", 'wb') do |out|
          sparse.each_pair do |key,value|
            out << (key + "\n")
          end
        end
        chunk_number += 1
        sparse = Hash.new {|h,k| h[k] = 0}
      end
    end

    p "writing #{sparse.size} - final"
    File.open("output/tilelists_update/#{server}_#{zoom}_#{chunk_number}_tiles.txt", 'wb') do |list|
      sparse.each_pair do |key,value|
        list << (key + "\n")
      end
    end
    chunk_number += 1
    sparse = nil
  end
end
