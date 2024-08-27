# It's easy to add more libraries or choose different versions. Any libraries
# specified here will be installed and made available to your morph.io scraper.
# Find out more: https://morph.io/documentation/ruby

source "https://rubygems.org"

ruby File.read(File.dirname(__FILE__) + "/.ruby-version")

gem "sqlite_magic"
gem "mechanize"
gem "pry"
gem "tty-cursor"
gem "tty-progressbar"
gem "zeitwerk"
gem "rspec"
gem "aws-sdk-s3"
gem "aws-record"
gem "googleauth"
gem "google-apis-sheets_v4"
gem "tzinfo"
gem "tzinfo-data"

group :development do
  gem "foreman"
  gem 'sorbet-runtime'
  gem 'sorbet'
  gem 'tapioca', require: false
  gem "ruby-lsp-rspec", require: false
end
