#typed: true
require 'sqlite_magic'

class CivilServiceJobsScraper::ResultStore
  sig {params(db_file: String, limit: T.nilable(Integer)).void}
  def initialize(db_file: 'data.sqlite', limit: nil)
    @db = SqliteMagic::Connection.new(db_file)
    begin
      @db.create_table(:data, [:refcode], [:refcode])
    rescue SQLite3::SQLException => _
      puts "data table already exists"
    end

    @limit = limit
    @download_counter = 0
  end

  sig {params(limit: T.nilable(Integer)).returns(T::Array[T::Hash[String, String]]) }
  def all(limit: nil)
    query = "SELECT * FROM data"
    query << " LIMIT #{limit}" if limit
    @db.execute(query)
  end

  def count
    @db.execute("SELECT count(*) FROM data").first.values.first
  end

  sig {params(job: CivilServiceJobsScraper::Model::Job).returns(T::Boolean)}
  def exists?(job)
    @db.execute("select * from data where refcode=:refcode", job.refcode).any?
  end

  sig {params(job: CivilServiceJobsScraper::Model::Job).returns(T::Boolean)}
  def should_skip?(job)
    @limit && @download_counter >= @limit
  end

  def add(job,job_page)
    @download_counter += 1
    fields = job.fields
      .merge(job_page.side_panel_fields)
      .merge(body: job_page.body)
    @db.save_data([:refcode], fields, 'data')
  end
end
