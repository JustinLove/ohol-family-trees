module OHOLFamilyTrees
  class LogValueYXT
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
        current_v = nil
        current_y = nil
        current_x = nil
        tile.placements.sort {|a,b|
            (a.object <=> b.object)*8 +
              (a.y <=> b.y)*4 +
              (a.x <=> b.x)*2 +
              (a.ms_time <=> b.ms_time)
          }.each do |logline|
          if logline.object != current_v
            if current_v
              out << "\n"
            end
            current_v = logline.object
            current_y = nil
            current_x = nil
            out << "v#{logline.object}"
          end
          if logline.y != current_y
            current_y = logline.y
            current_x = nil
            out << "\ny#{logline.y - last_y}"
          end
          if logline.x != current_x
            current_x = logline.x
            out << "\n#{logline.x - last_x}"
          end
          out << " #{(logline.ms_time - last_time)/10}"
          last_time = logline.ms_time
          last_x = logline.x
          last_y = logline.y
        end
      end
    end
  end
end
