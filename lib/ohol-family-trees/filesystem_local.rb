require 'fileutils'

module OHOLFamilyTrees
  class FilesystemLocal
    attr_reader :output_dir

    def initialize(output_dir)
      @output_dir = output_dir
    end

    def write(path, &block)
      filepath = "#{output_dir}/#{path}"
      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, 'wb', &block)
    end

    def read(path, &block)
      filepath = "#{output_dir}/#{path}"
      if File.exist?(filepath)
        File.open(filepath, 'rb', &block)
      end
    end
  end
end
