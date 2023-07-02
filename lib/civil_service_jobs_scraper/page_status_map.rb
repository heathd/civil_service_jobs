
class CivilServiceJobsScraper::PageStatusMap
  attr_reader :page_status_map, :last_page, :status_display

  def initialize(status_display:)
    @page_status_mutex = Mutex.new
    @page_status_map = {}
    @page_map = {}
    @last_page = nil
    @status_display = status_display
  end

  def started?(page_number)
    @page_status_mutex.synchronize do
      @page_status_map.has_key?(page_number)
    end
  end

  def fetching!(page_number)
    status_display.result_page(page_number, "fetching")

    @page_status_mutex.synchronize do
      @page_status_map[page_number] = :fetching
    end
  end

  def complete!(result_page)
    page_number = result_page.current_page
    status_display.result_page(page_number, "complete")

    @page_status_mutex.synchronize do

      if @last_page.nil? || result_page.last_page > @last_page
        @last_page = result_page.last_page
      end

      @page_status_map[page_number] = :complete
      @page_map[page_number] = result_page
    end
  end

  def all_complete?
    @page_status_mutex.synchronize do
      if @last_page.nil?
        false
      else
        @page_status_map.keys.sort == (1..@last_page).to_a &&
          @page_status_map.all? {|k,v| v == :complete}
      end
    end
  end
end
