
class CivilServiceJobsScraper::ResultPage
  attr_reader :page, :status_display

  def initialize(page, status_display:)
    @page = page
    @status_display = status_display
  end

  def pagination
    @pagination ||= begin
      list_elems = page.css('div.search-results-panel-main-inner .search-results-pageform .search-results-paging-menu ul li')
      Pagination.new(list_elems)
    end
  end

  def last_page
    pagination.last_page
  end

  def current_page
    pagination.current_page
  end

  def next_page?
    !! pagination.next_url
  end

  def next_page_url
    pagination.next_url
  end

  def job_list
    page
      .css('div.search-results-panel-main-inner ul[title="Job list"] li')
      .map { |li| JobTeaser.new(li) }
  end

  def enqueue_job_detail_fetchers!(agent, worker_pool, results_store)
    status_display.result_page(current_page, "expanding")
    skipped = enqueued = fetched = complete = 0

    job_list.each do |job_teaser|
      if results_store.exists?(job_teaser)
        status_display.increment(:page_detail_skip)
        skipped += 1 
        next
      end

      status_display.increment(:page_detail_enqueue)
      enqueued += 1 

      worker_pool.enqueue { |thread_num|
        status_display.thread_status(thread_num, "Fetch #{job_teaser.refcode}")
        status_display.increment(:page_detail_fetch)
        fetched += 1 

        job_page = JobPage.new(agent.get(job_teaser.job_page_url))
        results_store.add(job_teaser, job_page)

        status_display.thread_status(thread_num, "DONE  #{job_teaser.refcode}")
        status_display.increment(:page_detail_complete)
        complete += 1 
      }
    end

    status_display.result_page(current_page, "expanded skipped: #{skipped} enqueued: #{enqueued} fetched: #{fetched} complete: #{complete}")
  end

  def enqueue_next_page_fetcher!(agent, worker_pool, results_store, &callback)
    if next_page?
      worker_pool.enqueue do |thread_num| 
        r = ResultPage.new(agent.get(next_page_url))
        callback.call(r)
        r.expand!(agent,worker_pool, results_store)
      end
    else
      worker_pool.reached_last_page!
    end
  end
end
