# typed: true

class CivilServiceJobsScraper::Model::Job
  sig {returns(T::Hash[String, String])}
  attr_reader :fields

  sig {params(fields: T.any(T::Hash[String, String], T::Hash[Symbol, String])).void }
  def initialize(fields)
    @fields = stringify_keys(fields)
    convert_refcode!
  end

  sig {params(
    job_teaser: CivilServiceJobsScraper::Page::JobTeaser,
    job_detail: T.nilable(CivilServiceJobsScraper::Page::JobDetail)).returns(CivilServiceJobsScraper::Model::Job)}
  def self.from_scrape(job_teaser, job_detail = nil)
    fields = T.let(
      if job_detail
        job_teaser.fields
          .merge(job_detail.side_panel_fields)
          .merge(body: job_detail.body)
      else
        job_teaser.fields
      end,
      T::Hash[Symbol, String]
    )
    CivilServiceJobsScraper::Model::Job.new(fields)
  end

  sig {params(hash: T::Hash[String, String]).returns(CivilServiceJobsScraper::Model::Job) }
  def self.from_sqlite_record(hash)
    CivilServiceJobsScraper::Model::Job.new(hash)
  end

  sig {params(kv: T.any(T::Hash[String, String], T::Hash[Symbol, String])).returns(T::Hash[String, String])}
  def stringify_keys(kv)
    Hash[kv.map {|k,v| [k.to_s, v]}]
  end

  def convert_refcode!
    if @fields['refcode'] =~ /Reference : ([0-9]+)/
      @fields['refcode'] = $1
    end
  end

  sig {returns(String)}
  def refcode
    @fields['refcode']
  end

  sig {returns(T::Hash[String, String])}
  def attributes
    @fields
  end

  sig {params(attr: T.any(String, Symbol)).returns(T::Boolean)}
  def has_attribute?(attr)
    fields.has_key?(attr.to_s)
  end

  sig {params(attr: T.any(String, Symbol)).returns(T.nilable(String))}
  def attribute(attr)
    fields[attr.to_s]
  end
end
