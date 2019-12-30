require 'ohol-family-trees/tile_set'

module OHOLFamilyTrees
  class LogDiff
    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :zoom

    def initialize(filesystem, output_path, zoom)
      @output_path = output_path
      @filesystem = filesystem
      @zoom = zoom
    end

    def write(tile, timestamp)
      path = "#{output_path}/#{timestamp}/ml/#{zoom}/#{tile.tilex}/#{tile.tiley}.txt"
      #p path
      filesystem.write(path) do |out|
        last_x = 0
        last_y = 0
        last_time = 0
        tile.placements.each do |logline|
          out << "#{(logline.ms_time - last_time)/10} #{logline.x - last_x} #{logline.y - last_y} #{logline.object}\n"
          last_time = logline.ms_time
          last_x = logline.x
          last_y = logline.y
        end
      end
    end
  end
end
