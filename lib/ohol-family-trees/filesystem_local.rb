require 'fileutils'

module OHOLFamilyTrees
  class FilesystemLocal
    attr_reader :output_dir

    def initialize(output_dir)
      @output_dir = output_dir
    end

    def with_metadata(metadata)
      self
    end

    def write(path, metadata = {}, &block)
      filepath = "#{output_dir}/#{path}"
      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, 'wb', &block)
    end

    def read(path, &block)
      filepath = "#{output_dir}/#{path}"
      if File.exist?(filepath)
        File.open(filepath, 'rb', &block)
        return true
      end
    end

    def open(path)
      filepath = "#{output_dir}/#{path}"
      if File.exist?(filepath)
        return File.open(filepath, 'rb')
      end
    end

    def list(path)
      filepath = "#{output_dir}/#{path}"
      notprefix = ("#{output_dir}/".length)..-1
      if Dir.exist?(filepath)
        return Dir.glob(filepath + "/**/*").map { |entry|
          entry[notprefix]
        }
      end
      return []
    end
  end
end
