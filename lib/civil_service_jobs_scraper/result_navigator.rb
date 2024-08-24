# typed: true

class CivilServiceJobsScraper::ResultNavigator
  attr_reader :agent, :worker_pool, :result_page_download_tracker, :status_display

  sig { returns(CivilServiceJobsScraper::DynamoDbResultStore) }
  attr_reader :results_store

  sig {
    params(
      agent: Mechanize,
      worker_pool: CivilServiceJobsScraper::Worker,
      results_store: CivilServiceJobsScraper::DynamoDbResultStore,
      status_display: T.any(CivilServiceJobsScraper::LineBasedStatusDisplay, CivilServiceJobsScraper::TtyStatusDisplay),
      limit_pages: T.nilable(Integer)
    ).void
  }
  def initialize(agent:, worker_pool:, results_store:, status_display:, limit_pages: nil)
    @worker_pool = worker_pool
    @results_store = results_store
    @agent = agent
    @result_page_download_tracker = CivilServiceJobsScraper::ResultPageDownloadTracker.new(status_display: status_display)
    @status_display = status_display
    @page_counter = 0
    @limit_pages = limit_pages
  end

  sig { params( result_page: CivilServiceJobsScraper::Page::ResultPage ).void }
  def mark_complete_and_traverse_from(result_page)
    result_page_download_tracker.downloaded!(result_page)
    enqueue_job_detail_fetchers!(result_page)
    result_page_download_tracker.expanded!(result_page)

    pages = result_page.pagination_links
    pages.each do |page_number, url|
      next if result_page_download_tracker.started?(page_number)

      @page_counter += 1
      if @limit_pages && @page_counter >= @limit_pages
        result_page_download_tracker.skipped!(page_number)
      else
        result_page_download_tracker.fetching!(page_number)

        worker_pool.enqueue do |thread_num|
          r = CivilServiceJobsScraper::Page::ResultPage.new(agent.get(url))
          mark_complete_and_traverse_from(r)
        end
      end
    end
  end

  sig { params( result_page: CivilServiceJobsScraper::Page::ResultPage ).void }
  def enqueue_job_detail_fetchers!(result_page)
    status_display.result_page(result_page.current_page, "expanding")
    skipped = enqueued = fetched = complete = 0

    result_page.job_list.each do |job_teaser|
      job = CivilServiceJobsScraper::Model::Job.from_scrape(job_teaser)
      if results_store.exists?(job) || results_store.should_skip?(job)
        status_display.increment(:skip, result_page.current_page)
        skipped += 1
        next
      end

      status_display.increment(:enqueue, result_page.current_page)
      enqueued += 1

      worker_pool.enqueue { |thread_num|
        status_display.thread_status(thread_num, "Fetch #{job_teaser.refcode}")
        status_display.increment(:fetch, result_page.current_page)
        fetched += 1

        job_page = CivilServiceJobsScraper::Page::JobDetail.new(agent.get(job_teaser.job_page_url))
        job = CivilServiceJobsScraper::Model::Job.from_scrape(job_teaser, job_page)
        results_store.add(job)

        status_display.thread_status(thread_num, "DONE  #{job_teaser.refcode}")
        status_display.increment(:complete, result_page.current_page)
        complete += 1
      }
    end

    status_display.result_page(result_page.current_page, "expanded")
  end

  sig { void }
  def wait_for_completion
    worker_pool.wait_for_empty_and {
      result_page_download_tracker.all_expanded?
    }
  end
end
