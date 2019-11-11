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

    def list(path, &block)
      filesystems.each do |fs|
        return if fs.list(path, &block)
      end
    end
  end
end
