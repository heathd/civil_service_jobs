
class CivilServiceJobsScraper::Page::ResultPage
  attr_reader :page, :status_display

  def initialize(page, status_display:)
    @page = page
    @status_display = status_display
  end

  def pagination
    @pagination ||= begin
      list_elems = page.css('div.search-results-panel-main-inner .search-results-pageform .search-results-paging-menu ul li')
      CivilServiceJobsScraper::Pagination.new(list_elems)
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
      .map { |li| CivilServiceJobsScraper::Page::JobTeaser.new(li) }
  end
end
