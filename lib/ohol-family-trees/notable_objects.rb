module OHOLFamilyTrees
  module NotableObjects
    def self.read_notable_objects(filesystem, path, others = [])
      notable = others.clone
      filesystem.read(path) do |f|
        while line = f.gets
          notable << line.to_i
        end
      end
      return notable
    end
  end
end
