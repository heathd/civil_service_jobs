
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
    result_page.enqueue_job_detail_fetchers!(agent, worker_pool, results_store)

    pages = result_page.pagination.pages
    pages.each do |page_number, url|
      next if @page_status_map.started?(page_number)
      @page_status_map.fetching!(page_number)

      worker_pool.enqueue do |thread_num| 
        r = CivilServiceJobsScraper::ResultPage.new(agent.get(url))
        mark_complete_and_traverse_from(r)
      end
    end
  end

  def wait_for_completion
    worker_pool.wait_for_empty_and {
      @page_status_map.all_complete?
    }
  end
end
