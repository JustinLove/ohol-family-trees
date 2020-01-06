require 'ohol-family-trees/tile_set'

module OHOLFamilyTrees
  class KeyValueYX
    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :zoom

    def initialize(filesystem, output_path, zoom)
      @output_path = output_path
      @filesystem = filesystem
      @zoom = zoom
    end

    def write(tile, timestamp)
      path = "#{output_path}/#{timestamp}/kp/#{zoom}/#{tile.tilex}/#{tile.tiley}.txt"
      #p path
      filesystem.write(path) do |out|
        triples =
          tile.floors.map {|key,value| key + [value]} +
          tile.objects.map {|key,value| key + [value]}
        lastv = nil
        lasty = nil
        last_y = 0
        last_x = 0
        triples.sort {|a,b|
            (a[2] <=> b[2])*4 +
              (a[1] <=> b[1])*2 +
              (a[0] <=> b[0])
          }.each do |x, y, value|
          if value != lastv
            if lastv
              out << "\n"
            end
            lastv = value
            lasty = nil
            out << "v#{value}"
          end
          if y != lasty
            lasty = y
            out << "\n#{y - last_y}"
            last_y = y
          end
          out << " #{x - last_x}"
          last_x = x
        end
      end
    end

    def read(coords, timestamp)
      tilex,tiley = *coords
      path = "#{output_path}/#{timestamp}/kp/#{zoom}/#{tilex}/#{tiley}.txt"
      tile = Tile.new(coords, timestamp)
      #p path
      filesystem.read(path) do |file|
        currentValue = "0"
        x = 0
        y = 0
        file.each_line do |line|
          if line[0] == 'v'
            currentValue = line[1..-1].chomp
          else
            parts = line.split(' ').map(&:to_i)
            y += parts.shift
            parts.each do |dx| 
              x += dx
              if currentValue.start_with?('f')
                tile.set_floor(x, y, currentValue)
              else
                tile.set_object(x, y, currentValue)
              end
            end
          end
        end
      end
      p tile
      return tile
    end
  end
end
