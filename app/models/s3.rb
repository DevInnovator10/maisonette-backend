# frozen_string_literal: true

module S3
  def self.connection(options = {})
    @connection ||= begin
      require 'aws-sdk-s3'
      options.reverse_merge!(region: default_region)
      Aws::S3::Resource.new(options)
    end
  end

  def self.get(path, options = {})
    _options, bucket, region = parse_options(options)
    connection(region: region).bucket(bucket).object(path).get.body.read
  rescue Aws::S3::Errors::NoSuchKey => e
    raise e, path
  end

  def self.put(upload_path, data, options = {})
    options, bucket, region = parse_options(options)

    options[:content_type] = mime_type(upload_path)
    options[:body] = data.is_a?(String) ? data : data.read

    connection(region: region).bucket(bucket).object(upload_path).put(options)
    path_for_bucket(upload_path, bucket, region)
  end

  def self.delete(path, options = {})
    _options, bucket, region = parse_options(options)
    connection(region: region).bucket(bucket).object(path).delete
  rescue Aws::S3::Errors::NoSuchKey => e
    raise e, path
  end

  def self.upload_file(s3_upload_path, local_file_path, options = {})
    options, bucket, region = parse_options(options)

    options[:content_type] = mime_type(local_file_path)

    connection(region: region).bucket(bucket).object(s3_upload_path).upload_file(local_file_path, options)
    path_for_bucket(s3_upload_path, bucket, region)
  end

  def self.get_presigned_url(s3_file_path, options = {})
    options, bucket, region = parse_options(options)
    method = options.delete(:method)&.to_sym || :get

    connection(region: region).bucket(bucket).object(s3_file_path).presigned_url(method, options)
  end

  def self.objects(options = {})
    options, bucket, region = parse_options(options)

    connection(region: region).bucket(bucket).objects(options)
  end

  def self.object(s3_file_path, options = {})
    _options, bucket, region = parse_options(options)

    connection(region: region).bucket(bucket).object(s3_file_path)
  end

  class << self
    private

    def path_for_bucket(path, bucket = default_bucket, region = default_region)
      "https://#{bucket}.s3.#{region}.amazonaws.com/#{path}"
    end

    def default_bucket
      Maisonette::Config.fetch('aws.bucket')
    end

    def default_region
      Maisonette::Config.fetch('aws.region')
    end

    def mime_type(file)
      path = file.is_a?(File) ? file.path : file
      file_extension = path.split('.').last
      Mime::Type.lookup_by_extension(file_extension).to_s if file_extension
    end

    def parse_options(options)
      options = options.is_a?(String) ? { bucket: options } : options.deep_dup
      bucket = options.delete(:bucket) || default_bucket
      region = options.delete(:region) || default_region
      [options, bucket, region]
    end
  end
end
