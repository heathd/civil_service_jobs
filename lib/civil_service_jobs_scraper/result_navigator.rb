
class CivilServiceJobsScraper::ResultNavigator
  attr_reader :agent, :worker_pool, :results_store

  def initialize(agent:, worker_pool:, results_store:, status_display:)
    @worker_pool = worker_pool
    @results_store = results_store
    @agent = agent
    @page_status_map = CivilServiceJobsScraper::PageStatusMap.new(status_display: status_display)
  end

  def mark_complete_and_traverse_from(result_page)
    @page_status_map.complete!(result_page)
    result_page.enqueue_job_detail_fetchers!(result_page)

    pages = result_page.pagination.pages
    pages.each do |page_number, url|
      next if @page_status_map.started?(page_number)
      @page_status_map.fetching!(page_number)

      worker_pool.enqueue do |thread_num| 
        r = CivilServiceJobsScraper::Page::ResultPage.new(agent.get(url))
        mark_complete_and_traverse_from(r)
      end
    end
  end

  def enqueue_job_detail_fetchers!(result_page)
    status_display.result_page(result_page.current_page, "expanding")
    skipped = enqueued = fetched = complete = 0

    result_page.job_list.each do |job_teaser|
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

        job_page = CivilServiceJobsScraper::Page::JobDetail.new(agent.get(job_teaser.job_page_url))
        results_store.add(job_teaser, job_page)

        status_display.thread_status(thread_num, "DONE  #{job_teaser.refcode}")
        status_display.increment(:page_detail_complete)
        complete += 1 
      }
    end

    status_display.result_page(result_page.current_page, "expanded skipped: #{skipped} enqueued: #{enqueued} fetched: #{fetched} complete: #{complete}")
  end

  def wait_for_completion
    worker_pool.wait_for_empty_and {
      @page_status_map.all_complete?
    }
  end
end
