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

    def list(path, &block)
      response = client.list_objects_v2({
        :bucket => bucket,
        :prefix => path,
      })
      crazy = 0
      token = nil
      begin
        response = client.list_objects_v2({
          :bucket => bucket,
          :prefix => path,
          :continuation_token => token
        })
        token = response.next_continuation_token
        response.contents.each do |entry|
          yield entry.key
        end
        crazy += 1
      end while response.is_truncated && crazy <= 200
      return crazy > 0
    end
  end
end
