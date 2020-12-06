require 'chunky_png'

module OHOLFamilyTrees
  class ActPng

    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :zoom
    attr_reader :period
    attr_reader :size

    def initialize(filesystem, output_path, zoom, size, period)
      @output_path = output_path
      @filesystem = filesystem
      @zoom = zoom
      @period = period.to_f
      @size = size
    end

    def intensity(value)
      Math.log((value/period)+1) * 100
    end

    def hue(value)
      240 - [(intensity(value)*240).to_i, 240].min
    end

    def color(value)
      ChunkyPNG::Color.from_hsv(hue(value), 1, 0.5)
    end

    def write(tile, timestamp, coords)
      path = "#{output_path}/#{timestamp}/am/#{zoom}/#{coords[0]}/#{coords[1]}.png"
      #p path
      filesystem.write(path) do |out|
        png = ChunkyPNG::Image.new(size, size, ChunkyPNG::Color::TRANSPARENT)
        tile.each do |key,value|
          x = key[0]
          y = (size - 1) - key[1]
          #p ['sample', x, y]
          png[x,y] = color(value)
        end
        png.write(out)
      end
    end
  end
end
