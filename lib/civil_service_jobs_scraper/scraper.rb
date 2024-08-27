#typed:true

require 'mechanize'

class CivilServiceJobsScraper::Scraper
  sig {returns(T::Hash[Symbol, T.anything])}
  attr_reader :options

  sig {returns(T.any(
      CivilServiceJobsScraper::LineBasedStatusDisplay,
      CivilServiceJobsScraper::TtyStatusDisplay
    ))}
  attr_reader :status_display

  sig {params(
    options: T::Hash[Symbol, T.anything],
    status_display: T.any(
      CivilServiceJobsScraper::LineBasedStatusDisplay,
      CivilServiceJobsScraper::TtyStatusDisplay
    )).void}
  def initialize(options, status_display)
    @options = options
    @status_display = status_display
  end

  def agent
    @agent ||= Mechanize.new
  end

  def result_navigator
    @result_navigator ||= CivilServiceJobsScraper::ResultNavigator.new(
      agent: agent,
      worker_pool: CivilServiceJobsScraper::Worker.new(num_threads: options[:num_threads], status_display: status_display).start!,
      results_store: CivilServiceJobsScraper::DynamoDbResultStore.new(limit: T.cast(options[:limit_jobs], T.nilable(Integer))),
      status_display: status_display,
      limit_pages: T.cast(options[:limit_pages], T.nilable(Integer))
    )
  end

  def fetch_first_result_page
    start_page = agent.get("https://www.civilservicejobs.service.gov.uk/csr/index.cgi")
    CivilServiceJobsScraper::Page::ResultPage.new(
      start_page.form_with(id: "ID_context_search_form").submit)
  end

  def scrape!
    CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(operation: "Scrape start").save!

    first_result_page = fetch_first_result_page
    result_navigator.mark_complete_and_traverse_from(first_result_page)
    result_navigator.wait_for_completion

    sleep(15)

    puts "---== Scrape complete ==---"
    puts status_display.completion_message

    CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(
      operation: "Scrape complete",
      message: status_display.completion_message).save!
  end

end
