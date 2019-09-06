module OHOLFamilyTrees
  class FilesystemS3
    attr_reader :bucket

    def initialize(bucket)
      @bucket = bucket
    end

    def write(path, &block)
      out = StringIO.new
      yield out
      p [path, out.length]
    end
  end
end
