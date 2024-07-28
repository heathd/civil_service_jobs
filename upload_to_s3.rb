require 'aws-sdk-s3'

# Create an S3 client
s3 = Aws::S3::Client.new

# Define the bucket and file details
bucket_name = 'civil-service-jobs-data'
file_path = './csj.tar.gz'
object_key = 'csj.tar.gz' # The key (name) for the object in S3

# Upload the file to S3
begin
  s3.put_object({
    bucket: bucket_name,
    key: object_key,
    body: File.open(file_path, 'rb')
  })
  puts "File '#{file_path}' successfully uploaded to bucket '#{bucket_name}' as '#{object_key}'"
rescue Aws::S3::Errors::ServiceError => e
  puts "Failed to upload file: #{e.message}"
end
