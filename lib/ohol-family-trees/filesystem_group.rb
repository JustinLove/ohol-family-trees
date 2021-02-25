module OHOLFamilyTrees
  class FilesystemGroup
    attr_reader :filesystems

    def initialize(filesystems)
      @filesystems = filesystems
    end

    def with_metadata(metadata)
      self.class.new(filesystems.map {|fs| fs.with_metadata(metadata)})
    end

    def write(path, metadata = {}, &block)
      filesystems.each do |fs|
        fs.write(path, metadata, &block)
      end
    end

    def read(path, &block)
      filesystems.each do |fs|
        return if fs.read(path, &block)
      end
    end

    def open(path)
      filesystems.each do |fs|
        f = fs.open(path)
        return f if f
      end
    end

    def delete(path)
      filesystems.each do |fs|
        fs.delete(path)
      end
    end

    def list(path)
      filesystems.each do |fs|
        paths = fs.list(path)
        return paths if paths.length > 0
      end
      return []
    end
  end
end
