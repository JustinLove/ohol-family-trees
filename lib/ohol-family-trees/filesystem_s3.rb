require 'aws-sdk-s3'

module OHOLFamilyTrees
  class FilesystemS3
    attr_reader :bucket
    attr_reader :client
    attr_reader :default_metadata

    def initialize(bucket, metadata = {})
      @bucket = bucket
      @client = Aws::S3::Client.new
      @default_metadata = metadata
    end

    def with_metadata(metadata)
      self.class.new(bucket, default_metadata.merge(metadata))
    end

    def write(path, metadata = {}, &block)
      meta = default_metadata.merge(metadata)
      cache_control = meta.delete(:cache_control)
      out = StringIO.new
      yield out
      #p [bucket, path]
      out.rewind
      client.put_object({
        :body => out,
        :bucket => bucket,
        :key => path,
        :cache_control => cache_control,
        :metadata => meta,
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

    def open(path, &block)
      response = client.get_object({
        :bucket => bucket,
        :key => path,
      })
      return response.body
    rescue Aws::S3::Errors::NoSuchKey
      p ['not found', path]
      nil
    end

    def delete(path)
      client.delete_object({
        :bucket => bucket,
        :key => path,
      })
    rescue Aws::S3::Errors::NoSuchKey
      p ['not found', path]
      nil
    end

    def list(path)
      paths = []
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
        paths += response.contents.map { |entry| entry.key }
        crazy += 1
      end while response.is_truncated && crazy <= 200
      return paths
    end
  end
end
