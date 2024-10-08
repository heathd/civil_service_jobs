#typed: true

class CivilServiceJobsScraper::Page::ResultPage
  sig {returns(Mechanize::Page)}
  attr_reader :page

  sig {params(page: Mechanize::Page).void}
  def initialize(page)
    @page = page
  end

  def pagination_links
    pages_list = list_elems
      .reject { |e| e.text.strip =~ /^next/ }
      .select { |e| e.text.strip =~ /^[0-9]+$/ }
      .reject { |e| e.css('strong').any? }
      .select { |e| e.css('a').any? }
      .map { |e| e.css('a').first }
      .map { |a_tag| [a_tag.text.strip.to_i, a_tag.attr('href')] }

    Hash[pages_list]
  end

  def last_page
    e = list_elems.reject {|e| e.text =~ /^next/ }.last
    e.text.to_i
  end

  def current_page
    e = list_elems.find {|e| e.css('strong').any? }
    e && e.text.to_i
  end

  def next_page?
    !! next_page_url
  end

  def next_page_url
    e = list_elems.find {|e| e.text =~ /^next/ }
    e && e.css('a').first.attr('href').to_s
  end

  sig { returns(T::Array[CivilServiceJobsScraper::Page::JobTeaser]) }
  def job_list
    page
      .css('div.search-results-panel-main-inner ul[title="Job list"] li')
      .map { |li| CivilServiceJobsScraper::Page::JobTeaser.new(li) }
  end

private
  def list_elems
    @list_elems ||= page.css('div.search-results-panel-main-inner .search-results-pageform .search-results-paging-menu ul li')
  end
end
