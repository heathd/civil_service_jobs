require 'aws-sdk-s3'

# Create an S3 client
s3 = Aws::S3::Client.new

# Define the bucket and file details
bucket_name = 'civil-service-jobs-data'
file_path = './csj.tar.gz'
object_key = 'csj.tar.gz' # The key (name) for the object in S3

# Upload the file to S3
begin
  resp = s3.get_object({
    bucket: bucket_name,
    key: object_key,
    response_target: file_path
  })
  puts "File successfully downloaded '#{object_key}' from bucket '#{bucket_name}' to '#{file_path}'"
  puts "Metadata:"
  puts "content_length: #{resp.content_length/(1024*1024)}M"
  puts "content_type: #{resp.content_type}"
  puts "last_modified: #{resp.last_modified}"
  puts "version_id: #{resp.version_id}"
  puts "etag: #{resp.etag}"
rescue Aws::S3::Errors::ServiceError => e
  puts "Failed to download file: #{e.message}"
end
