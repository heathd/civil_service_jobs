
class CivilServiceJobsScraper::Pagination
  attr_reader :list_elems

  def initialize(list_elems)
    @list_elems = list_elems

    @current_page_elem = list_elems.find {|e| e.css('strong').any? }
    @next_page_elem = list_elems.find {|e| e.text =~ /^next/ }
  end

  def pages
    pages_list = list_elems
      .reject { |e| e.text.strip =~ /^next/ }
      .select { |e| e.text.strip =~ /^[0-9]+$/ }
      .reject { |e| e.css('strong').any? }
      .select { |e| e.css('a').any? }
      .map { |e| e.css('a').first }
      .map { |a_tag| [a_tag.text.strip.to_i, a_tag.attr('href')] }
    
    Hash[pages_list]
  end

  def current_page
    @current_page_elem && @current_page_elem.text.to_i
  end

  def last_page
    e = list_elems.reject {|e| e.text =~ /^next/ }.last
    e.text.to_i
  end

  def next_url
    @next_page_elem && @next_page_elem.css('a').first.attr('href')
  end
end
