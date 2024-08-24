# typed: true
require 'zeitwerk'
loader = Zeitwerk::Loader.new
loader.push_dir(File.dirname(__FILE__) + "/lib")
loader.setup
$LOAD_PATH << File.dirname(__FILE__) + "/config"

# require "dynamoid_local_config"
require "sorbet_init"
require "aws_record_local_config"

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

def scrape(options)
  agent = Mechanize.new
  CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(operation: "Scrape start").save!
  start_page = agent.get("https://www.civilservicejobs.service.gov.uk/csr/index.cgi")
  first_result_page = CivilServiceJobsScraper::Page::ResultPage.new(
    start_page.form_with(id: "ID_context_search_form").submit)

  n = CivilServiceJobsScraper::ResultNavigator.new(
    agent: agent,
    worker_pool: CivilServiceJobsScraper::Worker.new(num_threads: NUM_THREADS, status_display: STATUS).start!,
    results_store: CivilServiceJobsScraper::DynamoDbResultStore.new(limit: options[:limit_jobs]),
    status_display: STATUS,
    limit_pages: options[:limit_pages]
  )
  n.mark_complete_and_traverse_from(first_result_page)

  n.wait_for_completion

  CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(
    operation: "Scrape complete",
    message: STATUS.completion_message).save!

  sleep(15)
end

def transfer(options)
  results_store = CivilServiceJobsScraper::ResultStore.new(db_file: options[:db_file], limit: options[:limit_jobs])
  dynamodb_store = CivilServiceJobsScraper::DynamoDbResultStore.new()
  CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(operation: "Start transfer #{options[:db_file]}").save!

  puts "Querying dynamodb..."
  puts "There are #{dynamodb_store.all_existing_jobs.size} jobs in dynamodb"

  count = results_store.count
  slices = 0
  i = 0

  not_stored = results_store.all
    .map { |sqlite_job_record| CivilServiceJobsScraper::Model::Job.from_sqlite_record(sqlite_job_record) }
    .reject { |job| dynamodb_store.job_already_stored?(job.refcode) }

  puts "Had #{count} jobs to load"
  puts "#{not_stored.size} of those have not been stored in dynamodb yet"

  not_stored
    .each_slice(12) do |batch|
      if slices % 100 == 0
        puts "\n#{i} of #{count}"
      elsif slices % 10 == 0
        print "."
      end

      dynamodb_store.add_batch(batch)
      slices += 1
      i += batch.size
    end

  CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(operation: "Complete transfer of local data #{options[:db_file]}", message: "#{i} of #{count} records transferred").save!
end

def count(options)
  dynamodb_store = CivilServiceJobsScraper::DynamoDbResultStore.new()
  count = 0
  dynamodb_store.each do
    count += 1
  end
  puts count
end

if CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.operation_never_run?("Complete transfer")
  transfer(options)
end

scrape(options)
