
class CivilServiceJobsScraper::Page::JobTeaser
  attr_reader :li

  def initialize(li)
    @li = li
  end

  def fields
    {
      title: li.css('h3.search-results-job-box-title').text,
      department: li.css('.search-results-job-box-department').text,
      location: li.css('.search-results-job-box-location').text,
      salary: li.css('.search-results-job-box-salary').text,
      grade: li.css('.search-results-job-box-grade').text,
      stage: li.css('.search-results-job-box-stage').text,
      closingdate: li.css('.search-results-job-box-closingdate').text,
      refcode: li.css('.search-results-job-box-refcode').text
    }
  end

  def refcode
    fields[:refcode]
  end

  def title
    fields[:title]
  end

  def job_page_url
    li.css('.search-results-job-box-title a').attr('href').to_s
  end
end
