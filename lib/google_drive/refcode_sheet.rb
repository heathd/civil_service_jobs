class GoogleDrive::RefcodeSheet
  attr_reader :folder, :spreadsheet_id, :logger

  def initialize(folder:, spreadsheet_id:, logger: Logger.new(nil))
    @folder = folder
    @spreadsheet_id = spreadsheet_id
    @logger = logger
  end

  def job_already_in_sheet?(job)
    refcodes_of_jobs_already_in_sheet.include?(job.refcode)
  end

private
  def refcodes_of_jobs_already_in_sheet
    @refcodes_of_jobs_already_in_sheet ||= begin
      response = folder.get_spreadsheet_values(spreadsheet_id, 'Sheet1!C:C')
      if response.values
        response.values[1..-1].reject(&:empty?).map {|row| row.first}
      else
        []
      end
    end
  end

  sig {params(name: String).returns(String)}
  def create_spreadsheet(name)
    created_spreadsheet = sheets_service.create_spreadsheet(
      Google::Apis::SheetsV4::Spreadsheet.new(
        properties: {
          title: name
        }
      )
    )

    folder.add(created_spreadsheet)
    r.id
  end

  def add_job(job, i)
    if job_already_in_sheet?(job)
      logger.info "#{i}: #{job.refcode} #{job.title} -- already in sheet"
    else
      logger.info "#{i}: #{job.refcode} #{job.title} (#{job.created_at}) - loading"
      append_row(SpreadsheetRowForJob.new(job, job.body_record))
    end
  end
end
