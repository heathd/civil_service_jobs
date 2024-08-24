require 'zeitwerk'
loader = Zeitwerk::Loader.new
loader.push_dir(File.dirname(__FILE__) + "/lib")
loader.setup
$LOAD_PATH << File.dirname(__FILE__) + "/config"

require "dynamoid_local_config"

require 'mechanize'
require 'pry'
require 'optparse'

options = {
	db_file: 'data.sqlite',
	logger: :tty
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

NUM_THREADS = 4

STATUS = if options[:logger] == :line
	CivilServiceJobsScraper::LineBasedStatusDisplay.new(num_threads: NUM_THREADS)
else
	CivilServiceJobsScraper::TtyStatusDisplay.new(num_threads: NUM_THREADS)
end
STATUS.clear_screen

def scrape
  agent = Mechanize.new
  start_page = agent.get("https://www.civilservicejobs.service.gov.uk/csr/index.cgi")
  first_result_page = CivilServiceJobsScraper::Page::ResultPage.new(
    start_page.form_with(id: "ID_context_search_form").submit)

  n = CivilServiceJobsScraper::ResultNavigator.new(
    agent: agent,
    worker_pool: CivilServiceJobsScraper::Worker.new(num_threads: NUM_THREADS, status_display: STATUS).start!,
    results_store: CivilServiceJobsScraper::ResultStore.new(db_file: options[:db_file], limit: options[:limit_jobs]),
    status_display: STATUS,
    limit_pages: options[:limit_pages]
  )
  n.mark_complete_and_traverse_from(first_result_page)

  n.wait_for_completion
  sleep(15)
end

def transfer(options)
  results_store = CivilServiceJobsScraper::ResultStore.new(db_file: options[:db_file], limit: options[:limit_jobs])
  dynamodb_store = CivilServiceJobsScraper::DynamoDbResultStore.new()

  results_store.each do |job|
    puts job["refcode"]
    dynamodb_store.add(job)
  end
end

def count(options)
  dynamodb_store = CivilServiceJobsScraper::DynamoDbResultStore.new()
  count = 0
  dynamodb_store.each do
    count += 1
  end
  puts count
end


count(options)
