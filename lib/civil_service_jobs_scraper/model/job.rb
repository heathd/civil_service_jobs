# typed: true

class CivilServiceJobsScraper::Model::Job
  extend T::Sig

  sig {params(fields: T::Hash[String, String]).void }
  def initialize(fields)
    @fields = fields
    convert_refcode!
  end

  sig {params(
    job_teaser: CivilServiceJobsScraper::Page::JobTeaser,
    job_detail: CivilServiceJobsScraper::Page::JobDetail).returns(CivilServiceJobsScraper::Model::Job)}
  def self.from_scrape(job_teaser, job_detail)
    @job_teaser = job_teaser
    @job_detail = job_detail
    CivilServiceJobsScraper::Model::Job.new(job_teaser.fields
      .merge(job_detail.side_panel_fields)
      .merge(body: job_detail.body))
  end

  sig {params(hash: T::Hash[String, String]).returns(CivilServiceJobsScraper::Model::Job) }
  def self.from_sqlite_record(hash)
    CivilServiceJobsScraper::Model::Job.new(hash)
  end

  def convert_refcode!
    if @fields['refcode'] =~ /Reference : ([0-9]+)/
      @fields['refcode'] = $1
    end
  end

  def refcode
    @fields['refcode']
  end

  def attributes
    @fields
  end
end
