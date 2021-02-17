require 'pathname'
require 'aws-sdk-s3'

module Opsicle
  class S3Bucket
    attr_reader :bucket

    def initialize(client, bucket_name)
      @bucket = Aws::S3::Bucket.new(name: bucket_name, client: client.s3)
      raise UnknownBucket unless @bucket.exists?
    end

    def update(object)
      obj = bucket.object(object)
      obj.upload_file(Pathname.new(object))
    end
  end

  UnknownBucket = Class.new(StandardError)
end
