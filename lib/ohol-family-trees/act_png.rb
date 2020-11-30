require 'chunky_png'

module OHOLFamilyTrees
  class ActPng
    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :zoom

    def initialize(filesystem, output_path, zoom)
      @output_path = output_path
      @filesystem = filesystem
      @zoom = zoom
    end

    def write(tile, timestamp, coords)
      path = "#{output_path}/#{timestamp}/am/#{zoom}/#{coords[0]}/#{coords[1]}.png"
      #p path
      filesystem.write(path) do |out|
        png = ChunkyPNG::Image.new(256, 256, ChunkyPNG::Color::TRANSPARENT)
        tile.each do |key,value|
          x = key[0]
          y = 255 - key[1]
          #p ['sample', x, y]
          png[x,y] = ChunkyPNG::Color.from_hsv(240 - [value, 240].min, 1, 0.5)
        end
        png.write(out)
      end
    end
  end
end
