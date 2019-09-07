require 'aws-sdk-s3'

module OHOLFamilyTrees
  class FilesystemS3
    attr_reader :bucket
    attr_reader :client

    def initialize(bucket)
      @bucket = bucket
      @client = Aws::S3::Client.new
    end

    def write(path, &block)
      out = StringIO.new
      yield out
      #p [bucket, path]
      out.rewind
      client.put_object({
        :body => out,
        :bucket => bucket,
        :key => path,
      })
    end

    def read(path, &block)
      response = client.get_object({
        :bucket => bucket,
        :key => path,
      })
      yield response.body
      return true
    rescue Aws::S3::Errors::NoSuchKey
      p ['not found', path]
      return false
    end
  end
end
