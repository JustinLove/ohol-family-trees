require 'ohol-family-trees/tile_set'

module OHOLFamilyTrees
  class KeyPlain
    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :zoom

    def initialize(filesystem, output_path, zoom)
      @output_path = output_path
      @filesystem = filesystem
      @zoom = zoom
    end

    def write(tile, dir)
      path = "#{output_path}/#{dir}/#{zoom}/#{tile.tilex}/#{tile.tiley}.txt"
      #p path
      filesystem.write(path) do |out|
        tile.floors.each do |key,value|
          out << "#{key} #{value}\n"
        end
        tile.objects.each do |key,value|
          out << "#{key} #{value}\n"
        end
      end
    end

    def read(coords, timestamp)
      tilex,tiley = *coords
      path = "#{output_path}/#{timestamp}/#{zoom}/#{tilex}/#{tiley}.txt"
      tile = Tile.new(coords, timestamp)
      #p path
      filesystem.read(path) do |file|
        file.each_line do |line|
          parts = line.split(' ')
          if parts[2].start_with?('f')
            tile.set_floor(parts[0], parts[1], parts[2])
          else
            tile.set_object(parts[0], parts[1], parts[2])
          end
        end
      end
      return tile
    end
  end
end
