
class CivilServiceJobsScraper::ResultPageDownloadTracker
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

  def downloaded!(result_page)
    page_number = result_page.current_page
    status_display.result_page(page_number, "downloaded")

    @page_status_mutex.synchronize do

      if @last_page.nil? || result_page.last_page > @last_page
        @last_page = result_page.last_page
      end

      @page_status_map[page_number] = :downloaded
      @page_map[page_number] = result_page
    end
  end

  def skipped!(page_number)
    status_display.result_page(page_number, "skipped")

    @page_status_mutex.synchronize do
      @page_status_map[page_number] = :skipped
    end
  end

  def all_downloaded?
    @page_status_mutex.synchronize do
      if @last_page.nil?
        false
      else
        @page_status_map.all? {|k,v| %I{downloaded skipped}.include?(v)}
      end
    end
  end
end
