module OHOLFamilyTrees
  class FilesystemGroup
    attr_reader :filesystems

    def initialize(filesystems)
      @filesystems = filesystems
    end

    def write(path, &block)
      filesystems.each do |fs|
        fs.write(path, &block)
      end
    end

    def read(path, &block)
      filesystems.each do |fs|
        return if fs.read(path, &block)
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
