task :default => "vendor/dynamodb_local_latest.tar.gz"

file "vendor/dynamodb_local_latest.tar.gz" do |t|
  require 'open-uri'
  download = URI.open('https://d1ni2b6xgvw0s0.cloudfront.net/v2.x/dynamodb_local_latest.tar.gz')
  IO.copy_stream(download, t.name)
  FileUtils.mkdir("vendor/dynamodb")
  puts `cd vendor; tar zxf dynamodb_local_latest.tar.gz -C dynamodb`
end
