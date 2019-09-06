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
  end
end
