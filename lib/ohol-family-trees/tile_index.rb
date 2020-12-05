module OHOLFamilyTrees
  class TileIndex
    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :tile_type

    def initialize(filesystem, output_path, tile_type)
      @output_path = output_path
      @filesystem = filesystem
      @tile_type = tile_type
    end

    def write_index(triples, dir, zoom)
      path = "#{output_path}/#{dir}/#{tile_type}/#{zoom}/index.txt"
      p "write #{path}"
      filesystem.write(path) do |out|
        lasty = nil
        lastt = nil
        triples.sort {|a,b|
            (a[2] <=> b[2])*4 +
              (b[1] <=> a[1])*2 +
              (a[0] <=> b[0])
          }.each do |tilex, tiley, time|
          if time != lastt
            if lastt
              out << "\n"
            end
            lastt = time
            lasty = nil
            out << "t#{time}"
          end
          if tiley != lasty
            lasty = tiley
            out << "\n#{tiley}"
          end
          out << " #{tilex}"
        end
      end
    end

    def read_index(dir, zoom, cutoff)
      path = "#{output_path}/#{dir}/#{tile_type}/#{zoom}/index.txt"
      p "read #{path}"
      tile_list = []
      timestamp = dir
      filesystem.read(path) do |file|
        file.each_line do |line|
          if line[0] == 't'
            timestamp = line[1..-1].to_i
          end
          next if timestamp < cutoff
          parts = line.split(' ').map(&:to_i)
          tiley = parts.shift
          parts.each do |tilex|
            tile_list << [tilex,tiley,timestamp]
          end
        end
      end
      return tile_list
    end
  end
end
