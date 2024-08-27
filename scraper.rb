# typed: true
$LOAD_PATH << File.dirname(__FILE__) + "/config"
require 'init'
require 'optparse'

options = {
	db_file: 'data.sqlite',
	logger: :tty,
  num_threads: 4
}

OptionParser.new do |opts|
  opts.banner = "Usage: scraper.rb [options]"

  opts.on("-d FILENAME", "--db FILENAME", "Use FILENAME to store database") do |filename|
    options[:db_file] = filename
  end

  opts.on("--line-logger", "Use line based logger") do |v|
    options[:logger] = :line
  end

  opts.on("--limit-jobs LIMIT", "Limit jobs") do |limit|
    options[:limit_jobs] = limit.to_i
  end

  opts.on("--limit-pages LIMIT", "Limit pages") do |limit|
    options[:limit_pages] = limit.to_i
  end
end.parse!

status_display = if options[:logger] == :line
	CivilServiceJobsScraper::LineBasedStatusDisplay.new(num_threads: options[:num_threads])
else
	CivilServiceJobsScraper::TtyStatusDisplay.new(num_threads: options[:num_threads])
end
status_display.clear_screen

CivilServiceJobsScraper::Scraper.new(options, status_display).scrape!
