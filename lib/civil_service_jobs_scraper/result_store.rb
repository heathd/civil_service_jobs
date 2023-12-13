require 'sqlite_magic'

class CivilServiceJobsScraper::ResultStore
  def initialize(limit: nil)
    @db = SqliteMagic::Connection.new('data.sqlite')
    begin
      @db.create_table(:data, [:refcode], [:refcode])
    rescue SQLite3::SQLException => _
      puts "data table already exists"
    end

    @limit = limit
    @download_counter = 0
  end

  def exists?(job)
    @db.execute("select * from data where refcode=:refcode", job.refcode).any?
  end

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

