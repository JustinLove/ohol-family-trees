require 'lifelog'
require 'history'
require 'date'
require 'json'
require 'progress_bar'

#from_time = (Date.today - 2).to_time
#to_time = (Date.today - 0).to_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")
  next if dir.match("bigserver")

  lives = History.new

  puts dir

  #lives.load_dir("cache/"+dir, ((from_time - 60*60*24*1)..(to_time + 60*60*24*1)))
  lives.load_dir("cache/"+dir)

  #p lives.length
  next unless lives.length > 0

  #from = from_time.to_i
  #to = to_time.to_i

  server = dir.sub('lifeLog_', '').sub('.onehouronelife.com', '')
  #next unless server == 'bigserver2'

  zoom_levels = 28..28
  #zoom_levels = 24..24

  zoom_levels.each do |zoom|
    puts "#{server} #{zoom}"
    tile_width = 2**(32 - zoom)
    around = 500 / tile_width
    p around
    bar = ProgressBar.new(lives.lives.size)
    lives.lives.values.each_slice(100000).each_with_index do |chunk,i|
      puts "#{server} #{zoom} #{i}"
      puts chunk.size
      sparse = Hash.new {|h,k| h[k] = 0}
      chunk.each_with_index do |life,l|
        x, y = life.birth_coords
        unless x.nil? || y.nil?
          tilex = x / tile_width
          tiley = (-y / tile_width)
          #p [x, y, tilex, tiley]
          (-around..around).each do |dx|
            (-around..around).each do |dy|
              sparse[[tilex + dx,tiley + dy]] += 1
            end
          end
        end

        x, y = life.death_coords
        unless x.nil? || y.nil?
          tilex = x / tile_width
          tiley = (-y / tile_width)
          #p [x, y, tilex, tiley]
          (-around..around).each do |dx|
            (-around..around).each do |dy|
              sparse[[tilex + dx,tiley + dy]] += 1
            end
          end
        end

        if l % 100 == 99
          bar.increment! 100
        end
      end

      puts "writing #{sparse.size}"
      File.open("output/tilelists/#{server}_#{zoom}_#{i}_tiles.txt", 'wb') do |file|
        sparse.each_pair do |key,value|
          file << (key.join(' ') + "\n")
        end
      end
    end
  end

  #p sparse


end
