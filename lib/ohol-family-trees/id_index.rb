module OHOLFamilyTrees
  class IdIndex
    attr_reader :filesystem
    attr_reader :output_path
    attr_reader :tile_type

    def initialize(filesystem, output_path, tile_type)
      @output_path = output_path
      @filesystem = filesystem
      @tile_type = tile_type
    end

    def write_index(triples, dir)
      path = "#{output_path}/#{dir}/#{tile_type}/index.txt"
      p "write #{path}"
      included = true
      filesystem.write(path) do |out|
        triples.sort_by {|id,list,inc|
          list.length
        }.each do |id, list, inc|
          if inc != included
            if inc
              out << "+\n"
            else
              out << "-\n"
            end
            included = inc
          end
          out << "#{id} #{list.length}\n"
        end
      end
    end
  end
end
